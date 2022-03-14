def GenerateConfig(context):
    config={}
    config['resources'] = []
    config['outputs'] = []

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
            'graphDataScienceVersion': context.properties['graphDataScienceVersion'],
            'graphDataScienceLicenseKey': context.properties['graphDataScienceLicenseKey'],
            'bloomVersion': context.properties['bloomVersion'],
            'bloomLicenseKey': context.properties['bloomLicenseKey']
        }
    }
    config['resources'].append(deployment)

    return config
