#!/usr/bin/env bash
set -e
echo "Running core.sh"

echo "Using the settings:"
echo deployment \'$deployment\'
echo region \'$region\'
echo adminPassword \'$adminPassword\'
echo nodeCount \'$nodeCount\'
echo installGraphDataScience \'$installGraphDataScience\'
echo graphDataScienceLicenseKey \'$graphDataScienceLicenseKey\'
echo installBloom \'$installBloom\'
echo bloomLicenseKey \'$bloomLicenseKey\'
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
    firewall-cmd --zone=public --permanent --add-port=5000/tcp
    firewall-cmd --zone=public --permanent --add-port=6000/tcp
    firewall-cmd --zone=public --permanent --add-port=7000/tcp
    firewall-cmd --zone=public --permanent --add-port=7688/tcp
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

    echo Resolving latest Neo4j 4 release
    if ! curl --fail http://versions.neo4j-templates.com/target.json; then
        echo "Failed to resolve Neo4j version from http://versions.neo4j-templates.com, using latest"
        local -r graphDatabaseVersion="neo4j-enterprise"
    else
        local -r graphDatabaseVersion="neo4j-enterprise-$(curl http://versions.neo4j-templates.com/target.json | jq -r '.gcp."4.4"')"
    fi

    echo Adding neo4j yum repo...
    rpm --import https://debian.neo4j.com/neotechnology.gpg.key
    cat <<EOF >/etc/yum.repos.d/neo4j.repo
[neo4j]
name=Neo4j Yum Repo
baseurl=https://yum.neo4j.com/stable/4.4
enabled=1
gpgcheck=1
EOF

    echo "Installing Graph Database..."
    export NEO4J_ACCEPT_LICENSE_AGREEMENT=yes
    yum -y install "${graphDatabaseVersion}"
    systemctl enable neo4j
}

install_apoc_plugin() {
    echo "Installing APOC..."
    mv /var/lib/neo4j/labs/apoc-*-core.jar /var/lib/neo4j/plugins
}

configure_graph_data_science() {
    if [[ "${installGraphDataScience}" == True && "${nodeCount}" == 1 ]]; then
        echo "Installing Graph Data Science..."
        cp -p /var/lib/neo4j/products/neo4j-graph-data-science-*.jar /var/lib/neo4j/plugins
    fi
    if [[ $graphDataScienceLicenseKey != None ]]; then
        echo "Writing GDS license key..."
        mkdir -p /etc/neo4j/licenses
        chown neo4j:neo4j /etc/neo4j/licenses
        echo "${graphDataScienceLicenseKey}" >/etc/neo4j/licenses/neo4j-gds.license
        sed -i '$a gds.enterprise.license_file=/etc/neo4j/licenses/neo4j-gds.license' /etc/neo4j/neo4j.conf
    fi
}

configure_bloom() {
    if [[ $installBloom == True ]]; then
        echo "Installing Bloom..."
        cp -p /var/lib/neo4j/products/bloom-plugin-*.jar /var/lib/neo4j/plugins
    fi
    if [[ $bloomLicenseKey != None ]]; then
        echo "Writing Bloom license key..."
        mkdir -p /etc/neo4j/licenses
        chown neo4j:neo4j /etc/neo4j/licenses
        echo "${bloomLicenseKey}" >/etc/neo4j/licenses/neo4j-bloom.license
        sed -i '$a neo4j.bloom.license_file=/etc/neo4j/licenses/neo4j-bloom.license' /etc/neo4j/neo4j.conf
    fi
}

extension_config() {
    echo Configuring extensions and security in neo4j.conf...
    sed -i s~#dbms.unmanaged_extension_classes=org.neo4j.examples.server.unmanaged=/examples/unmanaged~dbms.unmanaged_extension_classes=com.neo4j.bloom.server=/bloom,semantics.extension=/rdf~g /etc/neo4j/neo4j.conf
    sed -i s/#dbms.security.procedures.unrestricted=my.extensions.example,my.procedures.*/dbms.security.procedures.unrestricted=gds.*,apoc.*,bloom.*/g /etc/neo4j/neo4j.conf
    echo "dbms.security.http_auth_allowlist=/,/browser.*,/bloom.*" >>/etc/neo4j/neo4j.conf
    echo "dbms.security.procedures.allowlist=apoc.*,gds.*,bloom.*" >>/etc/neo4j/neo4j.conf
}

set_cluster_configs() {
    local -r privateIP="$(hostname -i | awk {'print $NF'})"
    sed -i s/#dbms.default_advertised_address=localhost/dbms.default_advertised_address="${privateIP}"/g /etc/neo4j/neo4j.conf
    sed -i s/#causal_clustering.discovery_listen_address=:5000/causal_clustering.discovery_listen_address="${privateIP}":5000/g /etc/neo4j/neo4j.conf
    sed -i s/#causal_clustering.transaction_listen_address=:6000/causal_clustering.transaction_listen_address="${privateIP}":6000/g /etc/neo4j/neo4j.conf
    sed -i s/#causal_clustering.raft_listen_address=:7000/causal_clustering.raft_listen_address="${privateIP}":7000/g /etc/neo4j/neo4j.conf
    sed -i s/#dbms.connector.bolt.listen_address=:7687/dbms.connector.bolt.listen_address=0.0.0.0:7687/g /etc/neo4j/neo4j.conf
    sed -i s/#dbms.connector.http.advertised_address=:7474/dbms.connector.http.advertised_address="${privateIP}":7474/g /etc/neo4j/neo4j.conf
    sed -i s/#dbms.connector.https.advertised_address=:7473/dbms.connector.https.advertised_address="${privateIP}":7473/g /etc/neo4j/neo4j.conf
    sed -i s/#dbms.routing.enabled=false/dbms.routing.enabled=true/g /etc/neo4j/neo4j.conf
    sed -i s/#dbms.routing.advertised_address=:7688/dbms.routing.advertised_address="${privateIP}":7688/g /etc/neo4j/neo4j.conf
    sed -i s/#dbms.routing.listen_address=0.0.0.0:7688/dbms.routing.listen_address="${privateIP}":7688/g /etc/neo4j/neo4j.conf
    echo "dbms.routing.default_router=SERVER" >>/etc/neo4j/neo4j.conf
}

build_neo4j_conf_file() {
    echo "Configuring network in neo4j.conf..."
    sed -i 's/#dbms.default_listen_address=0.0.0.0/dbms.default_listen_address=0.0.0.0/g' /etc/neo4j/neo4j.conf
    echo "Configuring memory settings in neo4j.conf..."
    neo4j-admin memrec >>/etc/neo4j/neo4j.conf

    #this is to prevent SSRF attacks
    #Read more here https://neo4j.com/developer/kb/protecting-against-ssrf/
    echo "unsupported.dbms.cypher_ip_blocklist=10.0.0.0/8,172.16.0.0/12,192.168.0.0/16,169.254.169.0/24,fc00::/7,fe80::/10,ff00::/8" >> /etc/neo4j/neo4j.conf

    if [[ $nodeCount == 1 ]]; then
        echo "Running on a single node."
        sed -i s/#dbms.mode=CORE/dbms.mode=SINGLE/g /etc/neo4j/neo4j.conf
        echo "dbms.clustering.enable=true" >>/etc/neo4j/neo4j.conf
        set_cluster_configs
    else
        echo "Running on multiple nodes.  Configuring membership in neo4j.conf..."
        local clusterMembers
        for ip in $(gcloud compute instances list --format "value(networkInterfaces[0].networkIP.list())" --filter "labels.goog-dm: ${deployment}"); do
            local member="${ip}:5000"
            clusterMembers=${clusterMembers}${clusterMembers:+,}${member}
        done
        sed -i s/#causal_clustering.initial_discovery_members=localhost:5000,localhost:5001,localhost:5002/causal_clustering.initial_discovery_members=${clusterMembers}/g /etc/neo4j/neo4j.conf
        sed -i s/#dbms.mode=CORE/dbms.mode=CORE/g /etc/neo4j/neo4j.conf
        set_cluster_configs
    fi
}

start_neo4j() {
    echo "Starting Neo4j..."
    sudo systemctl start neo4j
    neo4j-admin set-initial-password "${adminPassword}"
    while [[ "$(curl -s -o /dev/null -m 3 -L -w '%{http_code}' http://localhost:7474)" != "200" ]]; do
        echo "Waiting for cluster to start"
        sleep 5
    done
}
extension_config() {
    echo Configuring extensions and security in neo4j.conf...
    sed -i s~#dbms.unmanaged_extension_classes=org.neo4j.examples.server.unmanaged=/examples/unmanaged~dbms.unmanaged_extension_classes=com.neo4j.bloom.server=/bloom,semantics.extension=/rdf~g /etc/neo4j/neo4j.conf
    sed -i s/#dbms.security.procedures.unrestricted=my.extensions.example,my.procedures.*/dbms.security.procedures.unrestricted=gds.*,apoc.*,bloom.*/g /etc/neo4j/neo4j.conf
    echo "dbms.security.http_auth_allowlist=/,/browser.*,/bloom.*" >>/etc/neo4j/neo4j.conf
    echo "dbms.security.procedures.allowlist=apoc.*,gds.*,bloom.*" >>/etc/neo4j/neo4j.conf
}

configure_firewalld
install_neo4j_from_yum
install_apoc_plugin
extension_config
build_neo4j_conf_file
configure_graph_data_science
configure_bloom
start_neo4j
