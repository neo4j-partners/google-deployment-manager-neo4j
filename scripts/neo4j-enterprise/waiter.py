def generate_config(context):
    waiter_name = context.env['deployment'] + '-waiter'
    waiter_config = {
        'name': waiter_name,
        'type': 'runtimeconfig.v1beta1.waiter',
        'metadata': {
            'dependsOn': [context.properties['dependsOn']]
        },
        'properties': {
            'parent': context.properties['runtime_config_name'],
            'waiter': waiter_name,
            'timeout': '500s',
            'success': {
                'cardinality': {
                    'path': '/success',
                    'number': context.properties['count'],
                },
            }
        }
    }

    config = {'resources': [], 'outputs': []}
    config['resources'].append(waiter_config)
    return config
