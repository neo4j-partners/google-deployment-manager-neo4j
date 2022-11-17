def GenerateConfig(context):
    region = context.properties['region']
    prefix = region + '-' + context.env['deployment']

    network_name = prefix + '-network'
    subnet_name = prefix + '-subnetwork'

    network_ref = '$(ref.{}.selfLink)'.format(network_name)
    subnet_ref = '$(ref.{}.selfLink)'.format(subnet_name)
    subnet_cidr = '10.128.0.0/20'

    network = {
        'name': network_name,
        'type': 'compute.v1.network',
        'properties': {
            'autoCreateSubnetworks': False,
        }
    }
    subnet = {
        'name': subnet_name,
        'type': 'compute.v1.subnetwork',
        'properties': {
            'region': region,
            'privateIpGoogleAccess': False,
            'ipCidrRange': subnet_cidr,
            'network': network_ref,
        }
    }
    config = {'resources': [], 'outputs': []}
    config['resources'].append(network)
    config['resources'].append(subnet)

    config['outputs'].append({
        'name': 'network_ref',
        'value': network_ref
    })
    config['outputs'].append({
        'name': 'subnet_ref',
        'value': subnet_ref
    })
    config['outputs'].append({
        'name': 'subnet_cidr',
        'value': subnet_cidr
    })
    return config
