# simple
This is a Google Deployment Manager (DM) template that installs Neo4j Enterprise Edition.  You can run it from the  CLI.

The template provisions Instance Group Managers (IGM), pd-ssd, and a Service Account to create a Runtime Config.

## Environment Setup
You will need a GCP account.

We also need to install glcoud.  Instructions for installing the Google Cloud SDK that includes gcloud are [here](https://cloud.google.com/sdk/).

To set up your Google environment, run the command:

    gcloud init

Now, you'll need a copy of this repo.  To make a local copy, run the commands:

    git clone https://github.com/neo4j-partners/google-deployment-manager-neo4j.git
    cd google-deployment-manager-neo4j
    cd simple

## Creating a Deployment
This repo contains different parameters files.  You can deploy with any of them using [deploy.sh](deploy.sh).  For example, to deploy the single configuration using <i>parameters.single.yaml</i>, run the command:

    ./deploy.sh <some deployment name> single

Using the <i>parameters.custom.yaml</i> configuration file, deploy could look like this:

    ./deploy.sh <some deployment name> custom

The script then passes the cluster configuration to GCP and builds your cluster automatically.

To access the cluster, open the [Google Cloud Console](http://cloud.google.com/console), navigate to Compute Engine and pick a node.  You can access the Neo4j Browser on port 7474 of the public IP of that node.

To view logs in near real-time, try:

    sudo tail -200 /var/log/messages

## Deleting a Deployment
To delete your deployment you can either run the command below or use the GUI in the [Google Cloud Console](http://cloud.google.com/console).

    gcloud deployment-manager deployments delete <some deployment name>

## Debugging a Deployment
There are a number of useful log files to debug. /var/log/messages is the startup agent log.  /var/log/neo4j/debug.log is the Neo4j log.