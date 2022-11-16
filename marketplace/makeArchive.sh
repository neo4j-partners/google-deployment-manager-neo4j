#!/bin/sh

rm archive.zip
mkdir tmp

cp neo4j.py tmp
cp neo4j.py.display tmp
cp neo4j.py.schema tmp
cp c2d_deployment_configuration.json tmp
cp test_config.yaml tmp

cp ../simple/*.py tmp
cp ../simple/*.py.schema tmp
cp ../simple/core.sh tmp

cd tmp

zip -r -X archive.zip *
mv archive.zip ../
cd ..
rm -rf tmp
