#!/usr/bin/env bash
set -e
echo "Running core-5.sh for Neo4j Community Edition"

echo "Using the settings:"
echo deployment \'$deployment\'
echo region \'$region\'
echo adminPassword \'$adminPassword\'
readonly nodeExternalIP="$(curl -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip)"

configure_firewalld() {
    echo Configuring local firewall
    firewall-cmd --zone=public --permanent --add-port=7474/tcp
    firewall-cmd --zone=public --permanent --add-port=7687/tcp
    firewall-cmd --zone=public --permanent --add-port=6362/tcp
    firewall-cmd --zone=public --permanent --add-port=7473/tcp
    firewall-cmd --zone=public --permanent --add-port=2003/tcp
    firewall-cmd --zone=public --permanent --add-port=2004/tcp
    firewall-cmd --zone=public --permanent --add-port=3637/tcp
}

install_neo4j_from_yum() {
    echo Disable unneeded repos
    sed -i '/\[rhui-codeready-builder-for-rhel-8-x86_64-rhui-debug-rpms\]/,/^ *\[/ s/enabled=1/enabled=0/' /etc/yum.repos.d/rh-cloud.repo
    sed -i '/\[rhui-codeready-builder-for-rhel-8-x86_64-rhui-rpms\]/,/^ *\[/ s/enabled=1/enabled=0/' /etc/yum.repos.d/rh-cloud.repo
    sed -i '/\[rhui-codeready-builder-for-rhel-8-x86_64-rhui-source-rpms\]/,/^ *\[/ s/enabled=1/enabled=0/' /etc/yum.repos.d/rh-cloud.repo
    sed -i '/\[rhui-rhel-8-for-x86_64-appstream-rhui-debug-rpms\]/,/^ *\[/ s/enabled=1/enabled=0/' /etc/yum.repos.d/rh-cloud.repo
    sed -i '/\[rhui-rhel-8-for-x86_64-appstream-rhui-source-rpms\]/,/^ *\[/ s/enabled=1/enabled=0/' /etc/yum.repos.d/rh-cloud.repo
    sed -i '/\[rhui-rhel-8-for-x86_64-baseos-rhui-debug-rpms\]/,/^ *\[/ s/enabled=1/enabled=0/' /etc/yum.repos.d/rh-cloud.repo
    sed -i '/\[rhui-rhel-8-for-x86_64-baseos-rhui-source-rpms\]/,/^ *\[/ s/enabled=1/enabled=0/' /etc/yum.repos.d/rh-cloud.repo
    sed -i '/\[rhui-rhel-8-for-x86_64-highavailability-debug-rhui-rpms\]/,/^ *\[/ s/enabled=1/enabled=0/' /etc/yum.repos.d/rh-cloud.repo
    sed -i '/\[rhui-rhel-8-for-x86_64-highavailability-rhui-rpms\]/,/^ *\[/ s/enabled=1/enabled=0/' /etc/yum.repos.d/rh-cloud.repo
    sed -i '/\[rhui-rhel-8-for-x86_64-highavailability-source-rhui-rpms\]/,/^ *\[/ s/enabled=1/enabled=0/' /etc/yum.repos.d/rh-cloud.repo
    sed -i '/\[rhui-rhel-8-for-x86_64-supplementary-rhui-debug-rpms\]/,/^ *\[/ s/enabled=1/enabled=0/' /etc/yum.repos.d/rh-cloud.repo
    sed -i '/\[rhui-rhel-8-for-x86_64-supplementary-rhui-rpms\]/,/^ *\[/ s/enabled=1/enabled=0/' /etc/yum.repos.d/rh-cloud.repo
    sed -i '/\[rhui-rhel-8-for-x86_64-supplementary-rhui-source-rpms\]/,/^ *\[/ s/enabled=1/enabled=0/' /etc/yum.repos.d/rh-cloud.repo

    echo Installing jq
    yum -y install jq

    echo Resolving latest Neo4j 5 release
    if ! curl --fail http://versions.neo4j-templates.com/target.json; then
        echo "Failed to resolve Neo4j version from http://versions.neo4j-templates.com, using latest"
        local -r graphDatabaseVersion="neo4j"
    else
        local -r graphDatabaseVersion="neo4j-$(curl http://versions.neo4j-templates.com/target.json | jq -r '.gcp."5"')"
    fi

    echo Adding neo4j yum repo...
    rpm --import https://debian.neo4j.com/neotechnology.gpg.key
    cat <<EOF >/etc/yum.repos.d/neo4j.repo
[neo4j]
name=Neo4j Yum Repo
baseurl=https://yum.neo4j.com/stable/5
enabled=1
gpgcheck=1
EOF

    echo "Installing Graph Database..."
    yum -y install "${graphDatabaseVersion}"
    systemctl enable neo4j
}
install_apoc_plugin() {
    echo "Installing APOC..."
    mv /var/lib/neo4j/labs/apoc-*-core.jar /var/lib/neo4j/plugins
}

build_neo4j_conf_file() {
    local -r privateIP="$(hostname -i | awk '{print $NF}')"
    echo "Configuring network in neo4j.conf..."
    sed -i 's/#server.default_listen_address=0.0.0.0/server.default_listen_address=0.0.0.0/g' /etc/neo4j/neo4j.conf
    sed -i s/#server.bolt.listen_address=:7687/server.bolt.listen_address=0.0.0.0:7687/g /etc/neo4j/neo4j.conf
    sed -i s/#server.bolt.advertised_address=:7687/server.bolt.advertised_address="${nodeExternalIP}":7687/g /etc/neo4j/neo4j.conf
    neo4j-admin server memory-recommendation >>/etc/neo4j/neo4j.conf

    #this is to prevent SSRF attacks
    #Read more here https://neo4j.com/developer/kb/protecting-against-ssrf/
    echo "internal.dbms.cypher_ip_blocklist=10.0.0.0/8,172.16.0.0/12,192.168.0.0/16,169.254.169.0/24,fc00::/7,fe80::/10,ff00::/8" >> /etc/neo4j/neo4j.conf

    echo "Running on a single node."
    sed -i s/#server.default_advertised_address=localhost/server.default_advertised_address="${nodeExternalIP}"/g /etc/neo4j/neo4j.conf

}
start_neo4j() {
    echo "Starting Neo4j..."
    sudo systemctl start neo4j
    neo4j-admin dbms set-initial-password "${adminPassword}"
    while [[ "$(curl -s -o /dev/null -m 3 -L -w '%{http_code}' http://localhost:7474)" != "200" ]]; do
        echo "Waiting for cluster to start"
        sleep 5
    done
}

gcloud_variable_update() {
  sudo tee -a /etc/yum.repos.d/google-cloud-sdk.repo << EOM
[google-cloud-cli]
name=Google Cloud CLI
baseurl=https://packages.cloud.google.com/yum/repos/cloud-sdk-el9-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=0
gpgkey=https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOM

  sudo dnf install -y google-cloud-cli

  gcloud beta runtime-config configs variables set deploymentSuccess completed --config-name status

}

configure_firewalld
install_neo4j_from_yum
install_apoc_plugin
build_neo4j_conf_file
start_neo4j
gcloud_variable_update
