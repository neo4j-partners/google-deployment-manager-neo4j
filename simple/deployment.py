
def GenerateConfig(context):
    prefix = context.env['deployment']
    instance_template_name = prefix + '-cluster-it'
    standalone_instance_template_name = prefix + '-standalone-it'
    public_ip_name = prefix + '-standalone-ip'
    igm_name = prefix + '-cluster' + '-igm'
    standalone_igm_name = prefix + '-standalone' + '-igm'
    startup_waiter_name = prefix + '-startup-waiter'
    startup_config_name = prefix + '-startup-config'

    firewall = {
        'name': 'firewall',
        'type': 'firewall.py',
        'properties': {
            'external_firewall_name': context.env['deployment'] + '-external',
            'internal_firewall_name': context.env['deployment'] + '-external',
        }
    }

    startup_waiter = {
        'name': 'startup-waiter',
        'type': 'startup_waiter.py',
        'properties': {
            'startup_config_name': startup_config_name,
            'startup_waiter_name': startup_waiter_name,
            'nodeCount': context.properties['nodeCount']
        }
    }
    config = {'resources': [], 'outputs': []}
    config['resources'].append(startup_waiter)
    config['resources'].append(firewall)

    if context.properties['nodeCount'] > 1:

        instance_group = {
            'name': 'instance-group',
            'type': 'instance_group.py',
            'properties': instance_group_properties(context, igm_name, instance_template_name)
        }
        config['resources'].append(instance_group)

        loadbalancer = {
            'name': 'loadbalancer',
            'type': 'loadbalancer.py',
            'properties': {
                'instance_group': '$(ref.instance-group.name)',
                # 'instance_group': '$(ref.' + igm_name + '.instanceGroup)',
                'region': context.properties['region'],
            }
        }
        config['resources'].append(loadbalancer)

        config['outputs'].append({
            'name': 'ip',
            'value': '$(ref.loadbalancer.ip)'
        })

    else:
        public_ip_addresss = {
            'name': 'standalone_ip_address',
            'type': 'standalone_ip_address.py',
            'properties': {
                'region': context.properties['region'],
                'public_ip_name': public_ip_name
            }
        }
        instance_group = {
            'name': 'instance-group',
            'type': 'instance_group.py',
            'properties': instance_group_properties(context, standalone_igm_name, standalone_instance_template_name,
                                                    '$(ref.standalone_ip_address.ip)')
        }

        config['resources'].append(instance_group)
        config['resources'].append(public_ip_addresss)

        config['outputs'].append({
            'name': 'ip',
            'value': '$(ref.standalone_ip_address.ip)'
        })
    return config


def instance_group_properties(context, igm_name, instance_template_name, public_ip=None):
    return {
        'region': context.properties['region'],
        'public_ip': public_ip,
        'instance_template_name': instance_template_name,
        'instance_group_manager_name': igm_name,
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
