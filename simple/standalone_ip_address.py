def generate_config(context):
    prefix = context.env['deployment']
    public_ip_name = prefix + '-standalone-ip'
    properties = context.properties
    public_ip_addresss = {
        'name': public_ip_name,
        'type': 'compute.v1.address',
        'properties': {
            'region': properties['region']
        }
    }
    config = {'resources': [], 'outputs': []}
    config['resources'].append(public_ip_addresss)

    config['outputs'].append({
        'name': 'ip',
        'value': '$(ref.' + public_ip_name + '.address)'
    })
    return config
