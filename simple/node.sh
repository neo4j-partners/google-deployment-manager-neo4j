#!/usr/bin/env bash

echo "Running node.sh"

echo "Using the settings:"
echo deployment \'$deployment\'
echo adminPassword \'$adminPassword\'
echo nodeCount \'$nodeCount\'
echo graphDatabaseVersion \'$graphDatabaseVersion\'
echo installGraphDataScience \'$installGraphDataScience\'
echo graphDataScienceLicenseKey \'$graphDataScienceLicenseKey\'
echo installBloom \'$installBloom\'
echo bloomLicenseKey \'$bloomLicenseKey\'
echo apocVersion \'$apocVersion\'

echo Turning off firewalld
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

echo Configuring extensions and security in neo4j.conf...
sed -i s~#dbms.unmanaged_extension_classes=org.neo4j.examples.server.unmanaged=/examples/unmanaged~dbms.unmanaged_extension_classes=com.neo4j.bloom.server=/bloom,semantics.extension=/rdf~g /etc/neo4j/neo4j.conf
sed -i s/#dbms.security.procedures.unrestricted=my.extensions.example,my.procedures.*/dbms.security.procedures.unrestricted=gds.*,bloom.*/g /etc/neo4j/neo4j.conf
sed -i '$a dbms.security.http_auth_allowlist=/,/browser.*,/bloom.*' /etc/neo4j/neo4j.conf
sed -i '$a dbms.security.procedures.allowlist=apoc.*,gds.*,bloom.*' /etc/neo4j/neo4j.conf

echo Configuring network in neo4j.conf...
sed -i 's/#dbms.default_listen_address=0.0.0.0/dbms.default_listen_address=0.0.0.0/g' /etc/neo4j/neo4j.conf

NODE_EXTERNAL_IP=`curl -H "Metadata-Flavor: Google" http://metadata/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip`
echo NODE_EXTERNAL_IP: ${NODE_EXTERNAL_IP}
sed -i s/#dbms.default_advertised_address=localhost/dbms.default_advertised_address=${NODE_EXTERNAL_IP}/g /etc/neo4j/neo4j.conf

echo Installing on ${nodeCount} node
if [[ $nodeCount == 1 ]]; then
  echo Running on a single node.
else
  echo Running on multiple nodes.
  coreMembers=`python3 parseCoreMembers.py $deployment`
  sed -i s/#causal_clustering.initial_discovery_members=localhost:5000,localhost:5001,localhost:5002/causal_clustering.initial_discovery_members=${coreMembers}/g /etc/neo4j/neo4j.conf
  sed -i s/#dbms.mode=CORE/dbms.mode=CORE/g /etc/neo4j/neo4j.conf
fi

echo Turning on SSL...
sed -i 's/dbms.connector.https.enabled=false/dbms.connector.https.enabled=true/g' /etc/neo4j/neo4j.conf
sed -i 's/#dbms.connector.bolt.tls_level=DISABLED/dbms.connector.bolt.tls_level=OPTIONAL/g' /etc/neo4j/neo4j.conf

/usr/bin/openssl req -x509 -newkey rsa:2048 -keyout private_key.pem -nodes -subj "/CN=neo4j-ssc/emailAddress=admin@neo4j.com/C=US/ST=CA/L=San  Mateo/O=Neo4J Customer/OU=Some Unit" -out public_cert.pem -days 365

# Logging
sed -i s/#dbms.logs.http.enabled/dbms.logs.http.enabled/g /etc/neo4j/neo4j.conf
sed -i s/#dbms.logs.query.enabled/dbms.logs.query.enabled/g /etc/neo4j/neo4j.conf
sed -i s/#dbms.logs.security.enabled/dbms.logs.security.enabled/g /etc/neo4j/neo4j.conf
sed -i s/#dbms.logs.debug.level/dbms.logs.debug.level/g /etc/neo4j/neo4j.conf

echo Turning on SSL...
sed -i 's/dbms.connector.https.enabled=false/dbms.connector.https.enabled=true/g' /etc/neo4j/neo4j.conf

echo Uncommenting dbms.ssl.policy configuration...
for svc in https bolt cluster backup
do
  echo For $svc copying certs and uncommenting default ssl policies
  sed -i s/#dbms.ssl.policy.$svc/dbms.ssl.policy.$svc/g /etc/neo4j/neo4j.conf
  mkdir -p /var/lib/neo4j/certificates/${svc}/trusted
  mkdir -p /var/lib/neo4j/certificates/${svc}/revoked
  cp private_key.pem /var/lib/neo4j/certificates/${svc}
  cp public_cert.pem /var/lib/neo4j/certificates/${svc}
  cp private_key.pem /var/lib/neo4j/certificates/${svc}/trusted
  cp public_cert.pem /var/lib/neo4j/certificates/${svc}/trusted
  # sed -i "$a dbms.ssl.policy.${svc}.trust_all=true" /etc/neo4j/neo4j.conf
done

sed -i s/private_key=private.key/private_key=private_key.pem/g /etc/neo4j/neo4j.conf
sed -i s/public_certificate=public.crt/public_certificate=public_cert.pem/g /etc/neo4j/neo4j.conf
sed -i '$a dbms.ssl.policy.bolt.trust_all=true' /etc/neo4j/neo4j.conf
sed -i '$a dbms.ssl.policy.https.trust_all=true' /etc/neo4j/neo4j.conf
sed -i '$a dbms.ssl.policy.cluster.trust_all=true' /etc/neo4j/neo4j.conf
sed -i '$a dbms.ssl.policy.backup.trust_all=true' /etc/neo4j/neo4j.conf

echo Changing certificate permissions
chown -R neo4j:neo4j /var/lib/neo4j/certificates
chmod -R 755 /var/lib/neo4j/certificates

if [[ $installGraphDataScience == True && $nodeCount == 1 ]]; then
  echo Installing Graph Data Science...
  cp /var/lib/neo4j/products/neo4j-graph-data-science-*.jar /var/lib/neo4j/plugins
fi

if [[ $installBloom == True ]]; then
  echo Installing Bloom...
  cp /var/lib/neo4j/products/bloom-plugin-*.jar /var/lib/neo4j/plugins
fi

if [[ $bloomLicenseKey != None ]]; then
  echo Writing Bloom license key...
  mkdir -p /etc/neo4j/licenses
  echo $bloomLicenseKey > /etc/neo4j/licenses/neo4j-bloom.license
  sed -i '$a neo4j.bloom.license_file=/etc/neo4j/licenses/neo4j-bloom.license' /etc/neo4j/neo4j.conf
fi

if [[ $graphDataScienceLicenseKey != None ]]; then
  echo Writing GDS license key...
  mkdir -p /etc/neo4j/licenses
  echo $graphDataScienceLicenseKey > /etc/neo4j/licenses/neo4j-gds.license
  sed -i '$a gds.enterprise.license_file=/etc/neo4j/licenses/neo4j-gds.license' /etc/neo4j/neo4j.conf
fi

echo Installing Apoc...
cp /var/lib/neo4j/labs/apoc-*.jar /var/lib/neo4j/plugins

echo Starting Neo4j...
service neo4j start
echo Setting initial password...
neo4j-admin set-initial-password ${adminPassword}
