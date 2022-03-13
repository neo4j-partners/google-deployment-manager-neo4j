def GenerateConfig(context):
    config={}
    config['resources'] = []

    runtimeconfigName = context.env['deployment'] + '-runtimeconfig'
    runtimeconfig = {
        'name': runtimeconfigName,
        'type': 'runtimeconfig.v1beta1.config',
        'properties': {
            'config': runtimeconfigName
        }
    }
    config['resources'].append(runtimeconfig)

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
                'ports': ['7473', '7474', '7687']
            }]
        }
    }
    config['resources'].append(firewall)

    return config