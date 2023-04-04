# google-deployment-manager-neo4j
These are Google Deployment Manager (DM) templates that deploy Neo4j Enterprise on Google Cloud Platform (GCP).  They set up Neo4j Graph Database, Graph Data Science and Bloom.  

* [scripts/neo4j-enterprise](scripts/neo4j-enterprise) is probably the best place to start.  It's a simple DM template that is a good starting point for CLI deployments or customization.
* [marketplace](marketplace) is the template used in the Neo4j Google Cloud Marketplace listing.  It's easiest to deploy that template directly from the Google Cloud Marketplace [here](https://console.cloud.google.com/marketplace/product/neo4j/neo4j-enterprise-edition).  The template has some Marketplace specific variables in it.  If deploying outside the marketplace, you probably want to use [scripts/neo4j-enterprise](scripts/neo4j-enterprise) instead.
