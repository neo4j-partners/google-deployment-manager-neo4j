#!/usr/bin/env bash

echo "Running node.sh"

echo "Using the settings:"
echo deployment \'$deployment\'
echo adminPassword \'$adminPassword\'
echo nodeCount \'$nodeCount\'
echo graphDatabaseVersion \'$graphDatabaseVersion\'
echo graphDataScienceVersion \'$graphDataScienceVersion\'
echo graphDataScienceLicenseKey \'$graphDataScienceLicenseKey\'
echo bloomVersion \'$bloomVersion\'
echo bloomLicenseKey \'$bloomLicenseKey\'
echo apocVersion \'$apocVersion\'

echo "Turning off firewalld"
systemctl stop firewalld
systemctl disable firewalld

echo Adding neo4j yum repo...
rpm --import https://debian.neo4j.com/neotechnology.gpg.key
echo "
[neo4j]
name=Neo4j Yum Repo
baseurl=http://yum.neo4j.com/stable
enabled=1
gpgcheck=1" > /etc/yum.repos.d/neo4j.repo

echo Installing Graph Database...
export NEO4J_ACCEPT_LICENSE_AGREEMENT=yes
yum -y install neo4j-enterprise-${graphDatabaseVersion}

echo Installing unzip...
yum -y install unzip

echo Configuring network in neo4j.conf...

sed -i 's/#dbms.default_listen_address=0.0.0.0/dbms.default_listen_address=0.0.0.0/g' /etc/neo4j/neo4j.conf

NODE_EXTERNAL_IP=`curl -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip`
echo NODE_EXTERNAL_IP: ${NODE_EXTERNAL_IP}
sed -i s/#dbms.default_advertised_address=localhost/dbms.default_advertised_address=${NODE_EXTERNAL_IP}/g /etc/neo4j/neo4j.conf

if [[ $nodeCount == 1 ]]; then
  echo Running on a single node.
else
  echo Running on multiple nodes.  Configuring membership in neo4j.conf...
  coreMembers=`python3 parseCoreMembers.py $deployment`
  sed -i s/#causal_clustering.initial_discovery_members=localhost:5000,localhost:5001,localhost:5002/causal_clustering.initial_discovery_members=${coreMembers}/g /etc/neo4j/neo4j.conf
  sed -i s/#dbms.mode=CORE/dbms.mode=CORE/g /etc/neo4j/neo4j.conf
fi

echo Turning on SSL...
sed -i 's/dbms.connector.https.enabled=false/dbms.connector.https.enabled=true/g' /etc/neo4j/neo4j.conf
#sed -i 's/#dbms.connector.bolt.tls_level=DISABLED/dbms.connector.bolt.tls_level=OPTIONAL/g' /etc/neo4j/neo4j.conf

answers() {
echo --
echo SomeState
echo SomeCity
echo SomeOrganization
echo SomeOrganizationalUnit
echo localhost.localdomain
echo root@localhost.localdomain
}
answers | /usr/bin/openssl req -newkey rsa:2048 -keyout private.key -nodes -x509 -days 365 -out public.crt

sed -i s/#dbms.ssl.policy.https/dbms.ssl.policy.https/g /etc/neo4j/neo4j.conf
mkdir -p /var/lib/neo4j/certificates/https/trusted
mkdir -p /var/lib/neo4j/certificates/https/revoked
cp private.key /var/lib/neo4j/certificates/https
cp public.crt /var/lib/neo4j/certificates/https

sed -i s/#dbms.ssl.policy.bolt/dbms.ssl.policy.bolt/g /etc/neo4j/neo4j.conf
mkdir -p /var/lib/neo4j/certificates/bolt/trusted
mkdir -p /var/lib/neo4j/certificates/bolt/revoked
cp private.key /var/lib/neo4j/certificates/bolt
cp public.crt /var/lib/neo4j/certificates/bolt

chown -R neo4j:neo4j /var/lib/neo4j/certificates
chmod -R 755 /var/lib/neo4j/certificates

# Logging
sed -i s/#dbms.logs.http.enabled/dbms.logs.http.enabled/g /etc/neo4j/neo4j.conf
sed -i s/#dbms.logs.query.enabled/dbms.logs.query.enabled/g /etc/neo4j/neo4j.conf
sed -i s/#dbms.logs.security.enabled/dbms.logs.security.enabled/g /etc/neo4j/neo4j.conf
sed -i s/#dbms.logs.debug.level/dbms.logs.debug.level/g /etc/neo4j/neo4j.conf

mkdir -p /etc/neo4j/downloads

if [[ $graphDataScienceVersion != None ]]; then
  echo Installing Graph Data Science...
  curl https://s3-eu-west-1.amazonaws.com/com.neo4j.graphalgorithms.dist/graph-data-science/neo4j-graph-data-science-${graphDataScienceVersion}-standalone.zip -o neo4j-graph-data-science-${graphDataScienceVersion}-standalone.zip
  unzip neo4j-graph-data-science-${graphDataScienceVersion}-standalone.zip
  mv neo4j-graph-data-science-${graphDataScienceVersion}.jar /var/lib/neo4j/plugins
fi

if [[ $bloomVersion != None ]]; then
  echo Installing Bloom...
  curl -L https://neo4j.com/artifact.php?name=neo4j-bloom-${bloomVersion}.zip -o neo4j-bloom-${bloomVersion}.zip
  unzip neo4j-bloom-${bloomVersion}.zip
  mv bloom-plugin-4.x-${bloomVersion}.jar /var/lib/neo4j/plugins
fi

echo Configuring Graph Data Science and Bloom in neo4j.conf...
sed -i s~#dbms.unmanaged_extension_classes=org.neo4j.examples.server.unmanaged=/examples/unmanaged~dbms.unmanaged_extension_classes=com.neo4j.bloom.server=/bloom,semantics.extension=/rdf~g /etc/neo4j/neo4j.conf
sed -i s/#dbms.security.procedures.unrestricted=my.extensions.example,my.procedures.*/dbms.security.procedures.unrestricted=gds.*,bloom.*/g /etc/neo4j/neo4j.conf
sed -i s/#dbms.security.procedures.allowlist=apoc.coll.*,apoc.load.*,gds.*/dbms.security.procedures.allowlist=apoc.coll.*,apoc.load.*,gds.*,bloom.*/g /etc/neo4j/neo4j.conf

if [[ $apocVersion != None ]]; then
  echo Installing APOC...
  curl -L https://github.com/neo4j-contrib/neo4j-apoc-procedures/releases/download/${apocVersion}/apoc-${apocVersion}-all.jar -o apoc-${apocVersion}-all.jar
  mv apoc-${apocVersion}-all.jar /var/lib/neo4j/plugins
fi

sed -i '$a ' /etc/neo4j/neo4j.conf
sed -i '$a # Bloom and EDS license files' /etc/neo4j/neo4j.conf

mkdir -p /etc/neo4j/licenses

if [[ $bloomLicenseKey != None ]]; then
  echo Writing Bloom license key file...
  # bloom license
  # https://neo4j.com/docs/bloom-user-guide/current/bloom-installation/installation-activation/
  echo $bloomLicenseKey > /etc/neo4j/licenses/neo4j-bloom.license
  echo Configuring Bloom license in neo4j.conf...
  sed -i '$a neo4j.bloom.license_file=/etc/neo4j/licenses/neo4j-bloom.license' /etc/neo4j/neo4j.conf
fi

if [[ $graphDataScienceLicenseKey != None ]]; then
  echo Writing GDS license key file...
  echo $graphDataScienceLicenseKey > /etc/neo4j/licenses/neo4j-gds.license
  echo Configuring GDS license in neo4j.conf...
  # gds license
  # https://neo4j.com/docs/graph-data-science/current/installation/installation-enterprise-edition/
  sed -i '$a gds.enterprise.license_file=/etc/neo4j/licenses/neo4j-gds.license' /etc/neo4j/neo4j.conf
fi

sed -i '$a ' /etc/neo4j/neo4j.conf
sed -i '$a # Bloom and EDS roles and permissions (updated in place)' /etc/neo4j/neo4j.conf

# Bloom http whitelist
sed -i '$a dbms.security.http_auth_allowlist=/,/browser.*,/bloom.*' /etc/neo4j/neo4j.conf

echo Starting Neo4j...
service neo4j start
neo4j-admin set-initial-password ${adminPassword}
