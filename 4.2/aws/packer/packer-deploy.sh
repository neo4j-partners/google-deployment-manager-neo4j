#!/bin/bash
if [[ $ENVIRONMENT == "PROD" ]]; then
export VERSION=4.2.2
packer build \
    -var "neo4j_edition=enterprise" \
    -var "neo4j_version=1:4.2.2" \
    packer-template.json

#packer build \
#    -var "neo4j_edition=community" \
#    -var "neo4j_version=1:4.2.2" \
#    packer-template.json

elif [[ $ENVIRONMENT == "TEST" ]]; then
export VERSION=4.2.2
packer build \
    -var "neo4j_edition=enterprise" \
    -var "neo4j_version=1:4.2.2" \
    packer-template-test.json

packer build \
    -var "neo4j_edition=community" \
    -var "neo4j_version=1:4.2.2" \
    packer-template-test.json
else
   echo "Parameter: $ENVIRONMENT is not valid"
fi