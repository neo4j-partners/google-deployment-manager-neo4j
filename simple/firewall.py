def GenerateConfig(context):
    properties = context.properties

    firewall_external = {
        'name': properties['external_firewall_name'],
        'type': 'compute.v1.firewall',
        'properties': {
            'sourceRanges': ['0.0.0.0/0'],
            'targetTags': [properties['external_firewall_name']],
            'allowed': [{
                'IPProtocol': 'tcp',
                'ports': ['7473', '7474', '7687', '6362', '2003', '2004', '3637']
            }]
        }
    }

    firewall_internal = {
        'name': properties['internal_firewall_name'],
        'type': 'compute.v1.firewall',
        'properties': {
            'sourceRanges': ['10.0.0.0/8'],
            'targetTags': [properties['internal_firewall_name']],
            'allowed': [{
                'IPProtocol': 'tcp',
                'ports': ['5000', '6000', '7000', '7688']
            }]
        }
    }
    config = {'resources': [], 'outputs': []}
    config['resources'].append(firewall_internal)
    config['resources'].append(firewall_external)

    return config
