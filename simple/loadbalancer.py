def GenerateConfig(context):
    properties = context.properties
    prefix = context.env['deployment']
    healthcheck_http_name = prefix + '-http-healthcheck'
    forwardingrule_name = prefix + '-http-forwardingrule'
    loadbalancer_name = prefix + '-http-loadbalancer'
    healthcheck_http = {
        'name': healthcheck_http_name,
        'type': 'compute.v1.regionHealthChecks',
        'properties': {
            'region': properties['region'],
            'type': 'TCP',
            'tcpHealthCheck': {
                'port': 7474
            },
        }
    }

    loadbalancer = {
        'name': loadbalancer_name,
        'type': 'compute.v1.regionBackendService',
        'properties': {
            'region': properties['region'],
            'healthChecks': ['$(ref.' + healthcheck_http_name + '.selfLink)'],
            'backends': [{'group': properties['instance_group']}],
            'protocol': 'TCP',
            'loadBalancingScheme': 'EXTERNAL',
        }
    }
    forwarding_rule = {
        'name': forwardingrule_name,
        'type': 'compute.v1.forwardingRule',
        'properties': {
            'ports': [7474, 7687],
            'region': properties['region'],
            'backendService': '$(ref.' + loadbalancer_name + '.selfLink)',
            'loadBalancingScheme': 'EXTERNAL',
        }
    }
    config = {'resources': [], 'outputs': []}
    config['resources'].append(healthcheck_http)
    config['resources'].append(loadbalancer)
    config['resources'].append(forwarding_rule)

    config['outputs'].append({
        'name': 'ip',
        'value': '$(ref.' + forwardingrule_name + '.IPAddress)'
    })
    return config
