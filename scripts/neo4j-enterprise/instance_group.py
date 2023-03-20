def generate_config(context):
    sourceImage = 'projects/neo4j-aura-gcp/global/images/neo4j-enterprise-edition-byol-v20230202'
    properties = context.properties
    prefix = context.env['deployment']

    instance_template = {
        'name': properties['instanceTemplateName'],
        'type': 'compute.v1.instanceTemplate',
        'properties': {
            'properties': {
                'machineType': context.properties['nodeType'],
                'tags': {
                    'items': [prefix + '-external', prefix + '-internal'],
                },
                'networkInterfaces': [{
                    'network':
                        properties['networkRef'],
                    'subnetwork':
                        properties['subnetRef'],
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
                    'diskType': context.properties['diskType'],
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
                        'https://www.googleapis.com/auth/cloudruntimeconfig',
                    ]
                }],
                'labels': {
                    'goog-dm': context.env['deployment']
                }
            }
        }
    }

    instance_group_manager = {
        'name': properties['instanceGroupManagerName'],
        'type': 'compute.v1.regionInstanceGroupManager',
        'properties': {
            'region': context.properties['region'],
            'baseInstanceName': context.env['deployment'] + '-cluster' + '-instance',
            'instanceTemplate': '$(ref.' + properties['instanceTemplateName'] + '.selfLink)',
            'targetSize': context.properties['nodeCount']
        }
    }
    # Standalone server
    if context.properties['publicIp']:
        instance_template['properties']['properties']['networkInterfaces'][0]['accessConfigs'][0]['natIP'] = context.properties['publicIp']
        instance_group_manager['type'] = 'compute.v1.instanceGroupManager'
        instance_group_manager['properties']['zone'] = context.properties['zone']

    config = {'resources': [], 'outputs': []}
    config['resources'].append(instance_template)
    config['resources'].append(instance_group_manager)
    config['outputs'].append({
        'name': 'name',
        'value': '$(ref.' + properties['instanceGroupManagerName'] + '.instanceGroup)'
    })
    return config

def generate_startup_script(context):
    script = '#!/usr/bin/env bash\n\n'

    script += 'deployment="' + context.env['deployment'] + '"\n'
    script += 'adminPassword="' + context.properties['adminPassword'] + '"\n'
    script += 'nodeCount="' + str(context.properties['nodeCount']) + '"\n'
    script += 'installGraphDataScience="' + str(context.properties['installGraphDataScience']) + '"\n'
    script += 'graphDataScienceLicenseKey="' + context.properties['graphDataScienceLicenseKey'] + '"\n'
    script += 'installBloom="' + str(context.properties['installBloom']) + '"\n'
    script += 'bloomLicenseKey="' + context.properties['bloomLicenseKey'] + '"\n'
    script += 'region="' + context.properties['region'] + '"\n'
    script += context.imports['core-' + context.properties['graphDatabaseVersion'] + '.sh']

    return script
