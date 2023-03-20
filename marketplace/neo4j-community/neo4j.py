def GenerateConfig(context):
    config = {'resources': [], 'outputs': []}

    deployment = {
        'name': 'deployment',
        'type': 'deployment.py',
        'properties': {
            'zone': context.properties['zone'],
            'nodeType': context.properties['nodeType'],
            'diskSize': context.properties['diskSize'],
            'diskType': context.properties['diskType'],
            'adminPassword': context.properties['adminPassword']
        }
    }
    config['resources'].append(deployment)
    config['outputs'].append({
        'name': 'url',
        'value': ''.join(['http://', '$(ref.deployment.ip)', ':7474'])
    })
    config['outputs'].append({
        'name': 'region',
        'value': context.properties['zone'][:-2]
    })

    return config
