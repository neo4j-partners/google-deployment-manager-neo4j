def generate_config(context):
    prefix = context.env['deployment']
    startup_waiter_name = prefix + '-startup-waiter'
    startup_config_name = prefix + '-startup-config'
    properties = context.properties

    startup_config = {
        'name': startup_config_name,
        'type': 'runtimeconfig.v1beta1.config',
        'properties': {
            'config': startup_config_name
        }
    }

    startup_waiter = {
        'name': startup_waiter_name,
        'type': 'runtimeconfig.v1beta1.waiter',
        'properties': {
            'waiter': startup_waiter_name,
            'parent': '$(ref.' + startup_config_name + '.name)',
            'timeout': '420s',
            'success': {
                'cardinality': {
                    'path': '/success',
                    'number': properties['nodeCount']
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
    config['outputs'].append({
        'name': 'configName',
        'value': startup_config_name
    })
    return config
