def GenerateConfig(context):
    config={}
    config['resources'] = []

    clusterJSON = {
        'name': context.env['deployment'] + '-cluster',
        'type': 'cluster.py',
        'properties': context.properties
    }
    config['resources'].append(clusterJSON)

    firewall = {
        'name': context.env['deployment'] + '-firewall',
        'type': 'compute.v1.firewall',
        'properties': {
            'sourceRanges': ['0.0.0.0/0'],
            'allowed': [{
                'IPProtocol': 'tcp',
                'ports': ['7473', '7474', '7687', '5000', '6000', '7000', '7688', '2003', '2004', '3637', '5005']
            }]
        }
    }
    config['resources'].append(firewall)

    return config