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

def GeneratePassword():
    import random
    categories = ['ABCDEFGHJKLMNPQRSTUVWXYZ', 'abcdefghijkmnopqrstuvwxyz', '123456789', '*-+.']
    password=[]
    for category in categories:
        password.insert(random.randint(0, len(password)), random.choice(category))
    while len(password) < 8:
        password.insert(random.randint(0, len(password)), random.choice(''.join(categories)))
    return ''.join(password)