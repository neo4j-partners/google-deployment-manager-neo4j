# marketplace
As an end user, you should have little use for the contents of this directory and almost certainly want to either use the Marketplace listing directly or [simple](../simple/).  If you're a Neo4j employee, updating the Google Marketplace listing, these notes may be helpful.

## Updating the Listing
To submit an updated listing, simply run ./makeArchive.sh and then submit the resulting zip to the Producer Portal [here](https://console.cloud.google.com/producer-portal/overview?project=neo4j-aura-gcp).

## Open Source Worksheet
Google requires completion of an open source worksheet.  Ours is [here](https://docs.google.com/spreadsheets/d/1z2YDbdeUVzHkpEmJGqYfcFHZcSd4rBPazYYH-zSJEg0/edit?usp=sharing).

# Build VM Image
You only need to do this occassionally, when the underlying OS is out of date.  The image has no Neo4j bits on it, so you don't need to do it when you bump the Neo4j version.

Open up a cloud shell.  While you could do this on your local machine with gcloud, it's way easier to just use a cloud shell.

Now we need to decide what OS image to use.  We're using the latest RHEL.  You can figure out what that is by running:

    gcloud compute images list

Then you're going to want to set these variables based on what you found above.

    IMAGE_VERSION=v20220406
    IMAGE_NAME=rhel-8-${IMAGE_VERSION}

Next, create an image for each license:

    LICENSE=neo4j-ee
    INSTANCE=${LICENSE}-${IMAGE_VERSION}
    gcloud compute instances create ${INSTANCE} \
    --project "neo4j-aura-gcp" \
    --zone "us-central1-f" \
    --machine-type "n2-standard-8" \
    --network "default" \
    --maintenance-policy "MIGRATE" \
    --scopes default="https://www.googleapis.com/auth/cloud-platform" \
    --image "https://www.googleapis.com/compute/v1/projects/rhel-cloud/global/images/${IMAGE_NAME}" --boot-disk-size "20" \
    --boot-disk-type "pd-ssd" \
    --boot-disk-device-name ${INSTANCE} \
    --no-boot-disk-auto-delete \
    --scopes "storage-rw"

Now we're going to delete the VM.  We'll be left with its boot disk.  This command takes a few minutes to run and doesn't print anything.  

    LICENSE=neo4j-ee
    INSTANCE=${LICENSE}-${IMAGE_VERSION}
    gcloud compute instances delete ${INSTANCE} \
    --project "neo4j-aura-gcp" \
    --zone "us-central1-f"

We were previously piping yes, but that doesn't seem to be working currently, so you'll have to type "y" a few times.

Now you need to attach the license ID to each image.  That process is described [here](https://cloud.google.com/launcher/docs/partners/technical-components#create_the_base_solution_vm).  
Note that you do not need to mount the disks and delete files since none were created.  To start, install the partner utilities:

    mkdir partner-utils
    cd partner-utils
    curl -O https://storage.googleapis.com/c2d-install-scripts/partner-utils.tar.gz
    tar -xzvf partner-utils.tar.gz
    sudo python setup.py install

Now apply the license:

    LICENSE=neo4j-ee
    INSTANCE=${LICENSE}-${IMAGE_VERSION}
    python image_creator.py \
    --project neo4j-aura-gcp \
    --disk ${INSTANCE} \
    --name ${INSTANCE} \
    --description ${INSTANCE} \
    --destination-project neo4j-aura-gcp \
    --license neo4j-aura-gcp/${LICENSE}

The license ID for the underlying RHEL image should be attached by default.
