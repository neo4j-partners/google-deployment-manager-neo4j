def GenerateConfig(context):
    sourceImage = 'projects/neo4j-aura-gcp/global/images/neo4j-enterprise-edition-byol-v20220418'

    properties = context.properties
    prefix = context.env['deployment']
    healthcheck_http_name = prefix + '-http-healthcheck'
    forwardingrule_name = prefix + '-http-forwardingrule'
    loadbalancer_name = prefix + '-http-loadbalancer'
    instance_template_name = context.env['deployment'] + '-cluster' + '-it'
    igm_name = context.env['deployment'] + '-cluster' + '-igm'

    instanceTemplate = {
        'name': instance_template_name,
        'type': 'compute.v1.instanceTemplate',
        'properties': {
            'properties': {
                'machineType': context.properties['nodeType'],
                'tags': {
                    'items': [prefix + '-ext'],
                },
                'networkInterfaces': [{
                    'network': 'https://www.googleapis.com/compute/v1/projects/' + context.env['project'] + '/global/networks/default',
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
                'metadata': {'items': [{'key':'startup-script', 'value': GenerateStartupScript(context)}]},
                'serviceAccounts': [{
                    'email': 'default',
                    'scopes': [
                        'https://www.googleapis.com/auth/cloud-platform',
                        'https://www.googleapis.com/auth/cloud.useraccounts.readonly',
                        'https://www.googleapis.com/auth/devstorage.read_only',
                        'https://www.googleapis.com/auth/logging.write',
                        'https://www.googleapis.com/auth/monitoring.write'
                    ]
                }],
                'labels': {
                   'goog-dm': context.env['deployment']
                }
            }
        }
    }

    instanceGroupManager = {
        'name': igm_name,
        'type': 'compute.v1.regionInstanceGroupManager',
        'properties': {
            'region': context.properties['region'],
            'baseInstanceName': context.env['deployment'] + '-cluster' + '-instance',
            'instanceTemplate': '$(ref.' + instance_template_name + '.selfLink)',
            'targetSize': context.properties['nodeCount']
        }
    }
    healthcheck_http = {
        'name': healthcheck_http_name,
        'type': 'compute.v1.regionHealthChecks',
        'properties': {
            'region': properties['region'],
            'type': 'TCP',
            'tcpHealthCheck': {
                'port': 7474
            },
        }
    }

    loadbalancer = {
        'name': loadbalancer_name,
        'type': 'compute.v1.regionBackendService',
        'properties': {
            'region': properties['region'],
            'healthChecks': ['$(ref.' + healthcheck_http_name + '.selfLink)'],
            'backends': [{'group': '$(ref.' + igm_name + '.instanceGroup)'}],
            'protocol': 'TCP',
            'loadBalancingScheme': 'EXTERNAL',
        }
    }
    forwarding_rule = {
        'name': forwardingrule_name,
        'type': 'compute.v1.forwardingRule',
        'properties': {
            'ports': [7474, 7687],
            'region': properties['region'],
            'backendService': '$(ref.' + loadbalancer_name + '.selfLink)',
            'loadBalancingScheme': 'EXTERNAL',
        }
    }
    config={}
    config['resources'] = []
    config['resources'].append(healthcheck_http)
    config['resources'].append(loadbalancer)
    config['resources'].append(forwarding_rule)
    config['resources'].append(instanceTemplate)
    config['resources'].append(instanceGroupManager)

    config['outputs'] = []
    config['outputs'].append({
        'name': 'ip',
        'value': '$(ref.' + forwardingrule_name + '.IPAddress)'
    })
    return config


def GenerateStartupScript(context):
    script = '#!/usr/bin/env bash\n\n'

    script+= 'echo "' + context.imports['parseCoreMembers.py'] + '">parseCoreMembers.py' + '\n'

    script += 'deployment="' + context.env['deployment'] + '"\n'
    script += 'adminPassword="' + context.properties['adminPassword'] + '"\n'
    script += 'nodeCount="' + str(context.properties['nodeCount']) + '"\n'
    script += 'graphDatabaseVersion="' + context.properties['graphDatabaseVersion'] + '"\n'
    script += 'installGraphDataScience="' + str(context.properties['installGraphDataScience']) + '"\n'
    script += 'graphDataScienceLicenseKey="' + context.properties['graphDataScienceLicenseKey'] + '"\n'
    script += 'installBloom="' + str(context.properties['installBloom']) + '"\n'
    script += 'bloomLicenseKey="' + context.properties['bloomLicenseKey'] + '"\n'
    script += 'region="' + context.properties['region'] + '"\n'
    script+= context.imports['core.sh']

    return script
