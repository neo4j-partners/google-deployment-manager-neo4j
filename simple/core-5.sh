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

    echo Resolving latest Neo4j 5 release
    if ! curl --fail http://versions.neo4j-templates.com/target.json; then
        echo "Failed to resolve Neo4j version from http://versions.neo4j-templates.com, using latest"
        local -r graphDatabaseVersion="neo4j-enterprise"
    else
        local -r graphDatabaseVersion="neo4j-enterprise-$(curl http://versions.neo4j-templates.com/target.json | jq -r '.gcp."5"')"
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
        cp /var/lib/neo4j/products/neo4j-graph-data-science-*.jar /var/lib/neo4j/plugins
    fi
    if [[ $graphDataScienceLicenseKey != None ]]; then
        echo "Writing GDS license key..."
        mkdir -p /etc/neo4j/licenses
        echo "${graphDataScienceLicenseKey}" >/etc/neo4j/licenses/neo4j-gds.license
        sed -i '$a gds.enterprise.license_file=/etc/neo4j/licenses/neo4j-gds.license' /etc/neo4j/neo4j.conf
    fi
}
configure_bloom() {
    if [[ $installBloom == True ]]; then
        echo "Installing Bloom..."
        cp /var/lib/neo4j/products/bloom-plugin-*.jar /var/lib/neo4j/plugins
    fi
    if [[ $bloomLicenseKey != None ]]; then
        echo "Writing Bloom license key..."
        mkdir -p /etc/neo4j/licenses
        echo "${bloomLicenseKey}" >/etc/neo4j/licenses/neo4j-bloom.license
        sed -i '$a dbms.bloom.license_file=/etc/neo4j/licenses/neo4j-bloom.license' /etc/neo4j/neo4j.conf
    fi
}
extension_config() {
    echo Configuring extensions and security in neo4j.conf...
    sed -i s~#server.unmanaged_extension_classes=org.neo4j.examples.server.unmanaged=/examples/unmanaged~server.unmanaged_extension_classes=com.neo4j.bloom.server=/bloom,semantics.extension=/rdf~g /etc/neo4j/neo4j.conf
    sed -i s/#dbms.security.procedures.unrestricted=my.extensions.example,my.procedures.*/dbms.security.procedures.unrestricted=gds.*,apoc.*,bloom.*/g /etc/neo4j/neo4j.conf
    echo "dbms.security.http_auth_allowlist=/,/browser.*,/bloom.*" >>/etc/neo4j/neo4j.conf
    echo "dbms.security.procedures.allowlist=apoc.*,gds.*,bloom.*" >>/etc/neo4j/neo4j.conf
}
build_neo4j_conf_file() {
    local -r privateIP="$(hostname -i | awk '{print $NF}')"
    echo "Configuring network in neo4j.conf..."
    sed -i 's/#server.default_listen_address=0.0.0.0/server.default_listen_address=0.0.0.0/g' /etc/neo4j/neo4j.conf
    sed -i s/#server.discovery.advertised_address=:5000/server.discovery.advertised_address="${privateIP}":5000/g /etc/neo4j/neo4j.conf
    sed -i s/#server.cluster.advertised_address=:6000/server.cluster.advertised_address="${privateIP}":6000/g /etc/neo4j/neo4j.conf
    sed -i s/#server.cluster.raft.advertised_address=:7000/server.cluster.raft.advertised_address="${privateIP}":7000/g /etc/neo4j/neo4j.conf
    sed -i s/#server.routing.advertised_address=:7688/server.routing.advertised_address="${privateIP}":7688/g /etc/neo4j/neo4j.conf
    sed -i s/#server.discovery.listen_address=:5000/server.discovery.listen_address="${privateIP}":5000/g /etc/neo4j/neo4j.conf
    sed -i s/#server.routing.listen_address=0.0.0.0:7688/server.routing.listen_address="${privateIP}":7688/g /etc/neo4j/neo4j.conf
    sed -i s/#server.cluster.listen_address=:6000/server.cluster.listen_address="${privateIP}":6000/g /etc/neo4j/neo4j.conf
    sed -i s/#server.cluster.raft.listen_address=:7000/server.cluster.raft.listen_address="${privateIP}":7000/g /etc/neo4j/neo4j.conf
    sed -i s/#server.bolt.listen_address=:7687/server.bolt.listen_address=0.0.0.0:7687/g /etc/neo4j/neo4j.conf
    sed -i s/#server.bolt.advertised_address=:7687/server.bolt.advertised_address="${privateIP}":7687/g /etc/neo4j/neo4j.conf
    neo4j-admin server memory-recommendation >>/etc/neo4j/neo4j.conf
    echo "server.metrics.enabled=true" >>/etc/neo4j/neo4j.conf
    echo "server.metrics.jmx.enabled=true" >>/etc/neo4j/neo4j.conf
    echo "server.metrics.prefix=neo4j" >>/etc/neo4j/neo4j.conf
    echo "server.metrics.filter=*" >>/etc/neo4j/neo4j.conf
    echo "server.metrics.csv.interval=5s" >>/etc/neo4j/neo4j.conf
    echo "dbms.routing.default_router=SERVER" >>/etc/neo4j/neo4j.conf
    if [[ ${nodeCount} == 1 ]]; then
        echo "Running on a single node."
        sed -i s/#server.default_advertised_address=localhost/server.default_advertised_address="${nodeExternalIP}"/g /etc/neo4j/neo4j.conf

    else
        echo "Running on multiple nodes.  Configuring membership in neo4j.conf..."
        local -r httpIP=$(gcloud compute forwarding-rules describe "${deployment}-http-forwardingrule" --format="value(IPAddress)" --region ${region})
        sed -i s/#server.default_advertised_address=localhost/server.default_advertised_address="${httpIP}"/g /etc/neo4j/neo4j.conf
        sed -i s/#initial.dbms.default_primaries_count=1/initial.dbms.default_primaries_count=3/g /etc/neo4j/neo4j.conf
        sed -i s/#initial.dbms.default_secondaries_count=0/initial.dbms.default_secondaries_count="$(expr ${nodeCount} - 3)"/g /etc/neo4j/neo4j.conf
        sed -i s/#server.bolt.listen_address=:7687/server.bolt.listen_address="${privateIP}":7687/g /etc/neo4j/neo4j.conf
        echo "dbms.cluster.minimum_initial_system_primaries_count=${nodeCount}" >>/etc/neo4j/neo4j.conf
        local clusterMembers
        for ip in $(gcloud compute instances list --format "value(networkInterfaces[0].networkIP.list())" --filter "labels.goog-dm: ${deployment}"); do
            local member="${ip}:5000"
            clusterMembers=${clusterMembers}${clusterMembers:+,}${member}
        done
        sed -i s/#dbms.cluster.discovery.endpoints=localhost:5000,localhost:5001,localhost:5002/dbms.cluster.discovery.endpoints=${clusterMembers}/g /etc/neo4j/neo4j.conf
    fi
}
start_neo4j() {
    echo "Starting Neo4j..."
    systemctl start neo4j
    neo4j-admin dbms set-initial-password "${adminPassword}"
    while [[ "$(curl -s -o /dev/null -m 3 -L -w '%{http_code}' http://localhost:7474)" != "200" ]]; do
        echo "Waiting for cluster to start"
        sleep 5
    done
}

configure_firewalld
install_neo4j_from_yum
install_apoc_plugin
extension_config
build_neo4j_conf_file
configure_graph_data_science
configure_bloom
start_neo4j
