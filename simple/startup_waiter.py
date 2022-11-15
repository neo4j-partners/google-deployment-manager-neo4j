def GenerateConfig(context):
    properties = context.properties
    startup_config = {
        'name': properties['startup_config_name'],
        'type': 'runtimeconfig.v1beta1.config',
        'properties': {
            'config': properties['startup_config_name']
        }
    }

    startup_waiter = {
        'name': properties['startup_waiter_name'],
        'type': 'runtimeconfig.v1beta1.waiter',
        'properties': {
            'waiter': properties['startup_waiter_name'],
            'parent': '$(ref.' + properties['startup_config_name'] + '.name)',
            'timeout': '420s',
            'success': {
                'cardinality': {
                    'path': '/success',
                    'number': context.properties['nodeCount']
                }
            },
            'failure': {
                'cardinality': {
                    'path': '/failure',
                    'number': 1
                }
            }
        }
    }
    config = {'resources': [], 'outputs': []}
    config['resources'].append(startup_config)
    config['resources'].append(startup_waiter)

    return config
