def generate_config(context):
    prefix = context.env['deployment']
    instance_template_name = prefix + '-cluster-it'
    standalone_instance_template_name = prefix + '-standalone-it'
    igm_name = prefix + '-cluster' + '-igm'
    standalone_igm_name = prefix + '-standalone' + '-igm'

    network = {
        'name': 'network',
        'type': 'network.py',
    }

    firewall = {
        'name': 'firewall',
        'type': 'firewall.py',
        'metadata': {
            'dependsOn': ['network'],
        },
        'properties': {
            'networkRef': '$(ref.network.networkRef)',
            'subnetCidr': '$(ref.network.subnetCidr)'
        }
    }

    startup_waiter = {
        'name': 'startup-waiter',
        'type': 'startup_waiter.py',
        'metadata': {
            'dependsOn': ['instance-group'],
        },
        'properties': {
            'nodeCount': context.properties['nodeCount']
        }
    }
    config = {'resources': [], 'outputs': []}
    config['resources'].append(network)
    config['resources'].append(firewall)
    config['resources'].append(startup_waiter)

    if context.properties['nodeCount'] > 1:

        instance_group = {
            'name': 'instance-group',
            'type': 'instance_group.py',
            'metadata': {
                'dependsOn': ['network'],
            },
            'properties': instance_group_properties(context, igm_name, instance_template_name)
        }
        config['resources'].append(instance_group)

        loadbalancer = {
            'name': 'loadbalancer',
            'type': 'loadbalancer.py',
            'properties': {
                'instance_group': '$(ref.instance-group.name)',
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
            'name': 'standalone-ip-address',
            'type': 'standalone_ip_address.py',
            'properties': {
                'region': context.properties['region'],
            }
        }
        instance_group = {
            'name': 'instance-group',
            'type': 'instance_group.py',
            'metadata': {
                'dependsOn': ['network'],
            },
            'properties': instance_group_properties(context, standalone_igm_name, standalone_instance_template_name,
                                                    public_ip='$(ref.standalone-ip-address.ip)')
        }

        config['resources'].append(instance_group)
        config['resources'].append(public_ip_addresss)

        config['outputs'].append({
            'name': 'ip',
            'value': '$(ref.standalone-ip-address.ip)'
        })
    return config


def instance_group_properties(context, igm_name, instance_template_name, public_ip=''):
    return {
        'region': context.properties['region'],
        'publicIp': public_ip,
        'networkRef': '$(ref.network.networkRef)',
        'subnetRef': '$(ref.network.subnetRef)',
        'instanceTemplateName': instance_template_name,
        'instanceGroupManagerName': igm_name,
        'startupConfigName': '$(ref.startup-waiter.configName)',
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
