#!/bin/bash

export VERSION=3.5.1
export STANDALONE_TEMPLATE=http://neo4j-cloudformation.s3.amazonaws.com/neo4j-enterprise-standalone-stack-$VERSION.json
export TEMPLATE=http://neo4j-cloudformation.s3.amazonaws.com/neo4j-enterprise-stack-$VERSION.json
export STACKNAME=neo4j-testdeploy-$(echo $VERSION | sed s/[^A-Za-z0-9]/-/g)-$(head -c 3 /dev/urandom | md5 | head -c 5)
export INSTANCE=r4.large
export REGION=us-east-1
export SSHKEY=david.allen.local
export RUN_ID=$(head -c 1024 /dev/urandom | md5)

# Returns a StackID that can be used to delete.
echo "Creating stack..."
STACK_ID=$(aws cloudformation create-stack \
   --stack-name $STACKNAME \
   --region $REGION \
   --template-url $TEMPLATE \
   --parameters ParameterKey=ClusterNodes,ParameterValue=3 \
                ParameterKey=InstanceType,ParameterValue=$INSTANCE \
                ParameterKey=NetworkWhitelist,ParameterValue=0.0.0.0/0 \
                ParameterKey=Password,ParameterValue=s00pers3cret \
                ParameterKey=SSHKeyName,ParameterValue=$SSHKEY \
                ParameterKey=VolumeSizeGB,ParameterValue=37 \
                ParameterKey=VolumeType,ParameterValue=gp2 \
  --capabilities CAPABILITY_NAMED_IAM | jq -r '.StackId')

echo $STACK_ID 

echo "Waiting for create to complete...."
aws cloudformation wait stack-create-complete --region us-east-1 --stack-name "$STACK_ID"

echo "Getting outputs"
JSON=$(aws cloudformation describe-stacks --region us-east-1 --stack-name "$STACK_ID")

echo $JSON

echo "Assembling results"
STACK_NAME=$(echo $JSON | jq -r .Stacks[0].StackName)
NEO4J_URI=$(echo $JSON | jq -cr '.Stacks[0].Outputs[] | select(.OutputKey | contains("Node1Ip")) | .OutputValue')
NEO4J_PASSWORD=$(echo $JSON | jq -cr '.Stacks[0].Outputs[] | select(.OutputKey | contains("Password")) | .OutputValue')

echo RUN_ID=$RUN_ID
echo STACK_NAME=$STACK_NAME
echo STACK_ID=$STACK_ID
echo NEO4J_URI=$NEO4J_URI
echo NEO4J_IP=$NEO4J_URI
echo NEO4J_PASSWORD=$NEO4J_PASSWORD