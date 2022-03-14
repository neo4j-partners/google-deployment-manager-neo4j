def GenerateConfig(context):
    config={}
    config['resources'] = []
    config['outputs'] = []

    adminPassword = GeneratePassword()

    config['outputs'].append({
        'name': 'adminPassword',
        'value': adminPassword
    })

    deployment = {
        'name': 'deployment',
        'type': 'deployment.py',
        'properties': {
            'adminPassword': adminPassword
        }
    }
    config['resources'].append(deployment)

    return config


def GetRegionsList(context):
    regions = []
    availableRegions = [
        'us-central1',
        'us-west1',
        'us-east1',
        'us-east4',
        'europe-west1',
        'europe-west2',
        'europe-west3',
        'asia-southeast1',
        'asia-east1',
        'asia-northeast1',
        'australia-southeast1'
    ]
    for region in availableRegions:
        if context.properties[region]:
            regions.append(region)
    return regions

def GeneratePassword():
    import random
    categories = ['ABCDEFGHJKLMNPQRSTUVWXYZ', 'abcdefghijkmnopqrstuvwxyz', '123456789', '*-+.']
    password=[]
    for category in categories:
        password.insert(random.randint(0, len(password)), random.choice(category))
    while len(password) < 8:
        password.insert(random.randint(0, len(password)), random.choice(''.join(categories)))
    return ''.join(password)