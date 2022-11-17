def generate_config(context):
    properties = context.properties
    external_firewall_name = context.env['deployment'] + '-external'
    internal_firewall_name = context.env['deployment'] + '-internal'

    firewall_external = {
        'name': external_firewall_name,
        'type': 'compute.v1.firewall',
        'properties': {
            'sourceRanges': ['0.0.0.0/0'],
            'network': properties['networkRef'],
            'targetTags': [external_firewall_name],
            'allowed': [{
                'IPProtocol': 'tcp',
                'ports': ['7473', '7474', '7687', '6362', '2003', '2004', '3637']
            }]
        }
    }

    firewall_internal = {
        'name': internal_firewall_name,
        'type': 'compute.v1.firewall',
        'properties': {
            'sourceRanges': [properties['subnetCidr']],
            'network': properties['networkRef'],
            'targetTags': [internal_firewall_name],
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
