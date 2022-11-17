def GenerateConfig(context):
    sourceImage = 'projects/neo4j-aura-gcp/global/images/neo4j-enterprise-edition-byol-v20220418'
    properties = context.properties
    prefix = context.env['deployment']

    instance_template = {
        'name': properties['instance_template_name'],
        'type': 'compute.v1.instanceTemplate',
        'properties': {
            'properties': {
                'machineType': context.properties['nodeType'],
                'tags': {
                    'items': [prefix + '-external', prefix + '-internal'],
                },
                'networkInterfaces': [{
                    'network':
                        properties['network_ref'],
                    'subnetwork':
                        properties['subnet_ref'],
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
                'metadata': {'items': [{'key': 'startup-script', 'value': generate_startup_script(context)}]},
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
                }],
                'labels': {
                    'goog-dm': context.env['deployment']
                }
            }
        }
    }
    if context.properties['public_ip']:
        instance_template['properties']['properties']['networkInterfaces'][0]['accessConfigs'][0]['natIP'] = context.properties['public_ip']

    instance_group_manager = {
        'name': properties['instance_group_manager_name'],
        'type': 'compute.v1.regionInstanceGroupManager',
        'properties': {
            'region': context.properties['region'],
            'baseInstanceName': context.env['deployment'] + '-cluster' + '-instance',
            'instanceTemplate': '$(ref.' + properties['instance_template_name'] + '.selfLink)',
            'targetSize': context.properties['nodeCount']
        }
    }

    config = {'resources': [], 'outputs': []}
    config['resources'].append(instance_template)
    config['resources'].append(instance_group_manager)
    config['outputs'].append({
        'name': 'name',
        'value': '$(ref.' + properties['instance_group_manager_name'] + '.instanceGroup)'
    })
    return config

def generate_startup_script(context):
    script = '#!/usr/bin/env bash\n\n'

    script += 'deployment="' + context.env['deployment'] + '"\n'
    script += 'adminPassword="' + context.properties['adminPassword'] + '"\n'
    script += 'nodeCount="' + str(context.properties['nodeCount']) + '"\n'
    script += 'graphDatabaseVersion="' + context.properties['graphDatabaseVersion'] + '"\n'
    script += 'installGraphDataScience="' + str(context.properties['installGraphDataScience']) + '"\n'
    script += 'graphDataScienceLicenseKey="' + context.properties['graphDataScienceLicenseKey'] + '"\n'
    script += 'installBloom="' + str(context.properties['installBloom']) + '"\n'
    script += 'bloomLicenseKey="' + context.properties['bloomLicenseKey'] + '"\n'
    script += 'region="' + context.properties['region'] + '"\n'
    script += context.imports['core.sh']

    return script
