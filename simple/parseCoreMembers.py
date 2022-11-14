import sys
import subprocess
import json

#print('Running parseCoreMembers.py')

deployment=sys.argv[1]
#print('Deployment is ' + deployment)

blob=subprocess.check_output('gcloud compute instances list --format=json', shell=True)
instances=json.loads(blob)

#print(json.dumps(j, indent=4, sort_keys=True))

output=''
for instance in instances:
    if instance['name'].startswith(deployment):
        externalIP=instance['networkInterfaces'][0]['networkIP']
        output=output+externalIP+':5000,'

output=output[:-1]
print(output)
