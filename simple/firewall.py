def generate_config(context):
    properties = context.properties
    external_firewall_name = context.env['deployment'] + '-external'
    internal_firewall_name = context.env['deployment'] + '-internal'
    iap_firewall_name = context.env['deployment'] + '-iap-ssh'

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

    iap_ssh_access = {
        'name': iap_firewall_name,
        'type': 'compute.v1.firewall',
        'properties': {
            'sourceRanges': ['35.235.240.0/20'],
            'network': properties['networkRef'],
            'targetTags': [external_firewall_name],
            'allowed': [{
                'IPProtocol': 'tcp',
                'ports': ['22']
            }]
        }
    }
    config = {'resources': [], 'outputs': []}
    config['resources'].append(firewall_internal)
    config['resources'].append(firewall_external)
    config['resources'].append(iap_ssh_access)

    return config
