
def GenerateConfig(context):
    config={}
    config['resources'] = []

    clusterJSON = {
        'name': context.env['deployment'] + '-cluster',
        'type': 'cluster.py',
        'properties': context.properties
    }
    config['resources'].append(clusterJSON)

    firewall_external = {
        'name': context.env['deployment'] + '-external',
        'type': 'compute.v1.firewall',
        'properties': {
            'sourceRanges': ['0.0.0.0/0'],
            'targetTags': [context.env['deployment'] + '-external'],
            'allowed': [{
                'IPProtocol': 'tcp',
                'ports': ['7473', '7474', '7687', '6362', '2003', '2004', '3637']
            }]
        }
    }
    firewall_internal = {
        'name': context.env['deployment'] + '-internal',
        'type': 'compute.v1.firewall',
        'properties': {
            'sourceRanges': ['10.0.0.0/8'],
            'targetTags': [context.env['deployment'] + '-internal'],
            'allowed': [{
                'IPProtocol': 'tcp',
                'ports': ['5000', '6000', '7000', '7688']
            }]
        }
    }
    config['resources'].append(firewall_external)
    config['resources'].append(firewall_internal)

    return config
