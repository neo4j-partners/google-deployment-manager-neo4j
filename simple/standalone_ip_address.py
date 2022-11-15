def GenerateConfig(context):
    properties = context.properties
    public_ip_addresss = {
        'name': properties['public_ip_name'],
        'type': 'compute.v1.address',
        'properties': {
            'region': properties['region']
        }
    }
    config = {'resources': [], 'outputs': []}
    config['resources'].append(public_ip_addresss)

    config['outputs'].append({
        'name': 'ip',
        'value': '$(ref.' + properties['public_ip_name'] + '.address)'
    })
    return config
