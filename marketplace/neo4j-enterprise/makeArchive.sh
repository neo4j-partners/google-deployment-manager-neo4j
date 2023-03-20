#!/bin/sh

rm archive.zip
mkdir tmp

cp neo4j.py tmp
cp neo4j.py.display tmp
cp neo4j.py.schema tmp
cp c2d_deployment_configuration.json tmp
cp test_config.yaml tmp

cp ../../scripts/neo4j-enterprise/*.py tmp
cp ../../scripts/neo4j-enterprise/*.py.schema tmp
cp ../../scripts/neo4j-enterprise/core-4.4.sh tmp
cp ../../scripts/neo4j-enterprise/core-5.sh tmp

cd tmp

zip -r -X archive.zip *
mv archive.zip ../
cd ..
rm -rf tmp
