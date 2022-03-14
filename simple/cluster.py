URL_BASE = 'https://www.googleapis.com/compute/v1/projects/'

def GenerateConfig(context):
    #sourceImage = URL_BASE + 'neo4j-public/global/images/neo4j-ee'
    sourceImage = 'projects/rhel-cloud/global/images/rhel-8-v20220303'

    instanceTemplateName = context.env['deployment'] + '-cluster' + '-it'
    instanceTemplate = {
        'name': instanceTemplateName,
        'type': 'compute.v1.instanceTemplate',
        'properties': {
            'properties': {
                'machineType': context.properties['nodeType'],
                'networkInterfaces': [{
                    'network': URL_BASE + context.env['project'] + '/global/networks/default',
                    'accessConfigs': [{
                        'name': 'External NAT',
                        'type': 'ONE_TO_ONE_NAT'
                    }]
                }],
                'disks': [{
                    'deviceName': 'boot',
                    'type': 'PERSISTENT',
                    'boot': True,
                    'autoDelete': True,
                    'initializeParams': {
                        'sourceImage': sourceImage
                    },
                    'diskType': 'pd-ssd',
                    'diskSizeGb': context.properties['diskSize']
                }],
                'metadata': {'items': [{'key':'startup-script', 'value':GenerateStartupScript(context)}]},
                'serviceAccounts': [{
                    'email': 'default',
                    'scopes': [
                        'https://www.googleapis.com/auth/cloud-platform',
                        'https://www.googleapis.com/auth/cloud.useraccounts.readonly',
                        'https://www.googleapis.com/auth/devstorage.read_only',
                        'https://www.googleapis.com/auth/logging.write',
                        'https://www.googleapis.com/auth/monitoring.write',
                        'https://www.googleapis.com/auth/cloudruntimeconfig'
                    ]
                }]
            }
        }
    }

    instanceGroupManager = {
        'name': context.env['deployment'] + '-cluster' + '-igm',
        'type': 'compute.v1.regionInstanceGroupManager',
        'properties': {
            'region': context.properties['region'],
            'baseInstanceName': context.env['deployment'] + '-cluster' + '-instance',
            'instanceTemplate': '$(ref.' + instanceTemplateName + '.selfLink)',
            'targetSize': context.properties['nodeCount']
        }
    }

    config={}
    config['resources'] = []
    config['resources'].append(instanceTemplate)
    config['resources'].append(instanceGroupManager)
    return config

def GenerateStartupScript(context):
    script = '#!/usr/bin/env bash\n\n'
    #script += 'DEPLOYMENT="' + context.env['deployment'] + '"\n'
 
    script += 'adminPassword="' + context.properties['adminPassword'] + '"\n'
    script += 'graphDatabaseVersion="' + context.properties['graphDatabaseVersion'] + '"\n'
    script += 'graphDataScienceVersion="' + context.properties['graphDataScienceVersion'] + '"\n'
    script += 'graphDataScienceLicenseKey="' + context.properties['graphDataScienceLicenseKey'] + '"\n'
    script += 'bloomVersion="' + context.properties['bloomVersion'] + '"\n'
    script += 'bloomLicenseKey="' + context.properties['bloomLicenseKey'] + '"\n'

    script+= context.imports['node.sh']

    return script