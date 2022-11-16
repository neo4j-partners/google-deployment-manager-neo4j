def GenerateConfig(context):
    config = {'resources': [], 'outputs': []}

    deployment = {
        'name': 'deployment',
        'type': 'deployment.py',
        'properties': {
            'region': context.properties['region'],
            'nodeCount': context.properties['nodeCount'],
            'nodeType': context.properties['nodeType'],
            'diskSize': context.properties['diskSize'],
            'adminPassword': context.properties['adminPassword'],
            'graphDatabaseVersion': context.properties['graphDatabaseVersion'],
            'installGraphDataScience': context.properties['installGraphDataScience'],
            'graphDataScienceLicenseKey': context.properties['graphDataScienceLicenseKey'],
            'installBloom': context.properties['installBloom'],
            'bloomLicenseKey': context.properties['bloomLicenseKey']
        }
    }
    config['resources'].append(deployment)
    config['outputs'].append({
        'name': 'url',
        'value': ''.join(['http://', '$(ref.deployment.ip)', ':7474'])
    })

    return config
