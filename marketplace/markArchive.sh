#!/bin/sh

rm archive.zip
mkdir tmp

cp neo4j.py tmp
cp neo4j.py.display tmp
cp neo4j.py.schema tmp
cp c2d_deployment_configuration.json tmp
cp test_config.yaml tmp

cp ../simple/deployment.py tmp
cp ../simple/cluster.py tmp
cp ../simple/node.sh tmp

cp -r resources tmp

zip -r -X archive.zip tmp
rm -rf tmp