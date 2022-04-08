# google-deployment-manager-neo4j
These are Google Deployment Manager (DM) templates that deploy Neo4j Enterprise on Google Cloud Platform (GCP).  They set up Neo4j Graph Database, Graph Data Science and Bloom.  

* [simple](simple) is probably the best place to start.  It's a simple DM template that is a good starting point for CLI deployments or customization. 
  The template uses self-signed certificates. 
 
When working with non-public data, please carefully follow instructions in <i>Neo4j SSL Setup - 4.x.pdf</i> to configure a proper CA-signed certificate.  This document links to resources and videos which further clarify configuration.
  
* Note that Neo4j browser tools may not work over https because browsers don't trust them.
* [marketplace](marketplace) is the template used in the Neo4j Google Cloud Marketplace listing.
  It's easiest to deploy that template directly from the Google Cloud Marketplace. The template has some Marketplace specific variables in it.  If deploying outside the marketplace, you probably want to use [simple](simple) instead.
  The same concerns about self-signed certificates apply.

Please note that if you want to enable enterprise features, please copy the default configuration file, and then add license keys.

To deploy this template, please configure gcloud locally and run a script like this:

    ./deploy.sh single-test-deployment my_config_variant

The deploy.sh script is simply passing in the first argument as the deployment name, and the second represents the parameter file variant, as shown below:

    deploy.sh

    #!/bin/sh
    DEPLOYMENT_NAME=$1
    PARAMETERS_FILE=$2
    gcloud deployment-manager deployments create ${DEPLOYMENT_NAME} --config parameters.${PARAMETERS_FILE}.yaml

