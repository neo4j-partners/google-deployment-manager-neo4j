def generate_config(context):
    runtime_config_name = context.env['deployment'] + '-runtimeconfig'
    fullName = 'projects/' + context.env['project'] + '/configs/' + runtime_config_name
    runtime_config = {
        'name': runtime_config_name,
        'type': 'runtimeconfig.v1beta1.config',
        'properties': {
            'config': runtime_config_name,
            'description': 'deploymentStatus'
        }
    }

    config = {'resources': [], 'outputs': []}
    config['resources'].append(runtime_config)
    config['outputs'].append({
        'name': 'fullName',
        'value': fullName
    })
    config['outputs'].append({
        'name': 'name',
        'value': runtime_config_name
    })
    return config
