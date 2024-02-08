def generate_config(context):
    prefix = context.env['deployment']
    standalone_instance_template_name = prefix + '-standalone-it'

    standalone_igm_name = prefix + '-standalone' + '-igm'
    region = context.properties['zone'][:-2]

    runtime_config = {
        'name': 'runtime_config',
        'type': 'runtime_config.py',
    }

    network = {
        'name': 'network',
        'type': 'network.py',
        'metadata': {
            'dependsOn': ['runtime_config'],
        },
        'properties': {
            'region': region,
        }
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

    config = {'resources': [], 'outputs': []}
    config['resources'].append(runtime_config)
    config['resources'].append(network)
    config['resources'].append(firewall)

    public_ip_address = {
        'name': 'standalone-ip-address',
        'type': 'standalone_ip_address.py',
        'properties': {
            'region': region,
        }
    }
    instance_group = {
        'name': 'instance-group',
        'type': 'instance_group.py',
        'metadata': {
            'dependsOn': ['network'],
        },
        'properties': instance_group_properties(context, standalone_igm_name, standalone_instance_template_name,
                                                region, public_ip='$(ref.standalone-ip-address.ip)')
    }

    waiter = {
        'name': 'waiter',
        'type': 'waiter.py',
        'properties': {
            'dependsOn': standalone_igm_name,
            'count': 1,
            'runtime_config_name': '$(ref.runtime_config.fullName)'
        }
    }

    config['resources'].append(instance_group)
    config['resources'].append(waiter)
    config['resources'].append(public_ip_address)

    config['outputs'].append({
        'name': 'ip',
        'value': '$(ref.standalone-ip-address.ip)'
    })
    config['outputs'].append({
        'name': 'neo4jbrowserurl',
        'value': 'http://$(ref.standalone-ip-address.ip):7474'
    })

    return config


def instance_group_properties(context, igm_name, instance_template_name, region,public_ip=''):
    return {
        'region': region,
        'zone': context.properties['zone'],
        'publicIp': public_ip,
        'networkRef': '$(ref.network.networkRef)',
        'subnetRef': '$(ref.network.subnetRef)',
        'instanceTemplateName': instance_template_name,
        'instanceGroupManagerName': igm_name,
        'nodeType': context.properties['nodeType'],
        'diskSize': context.properties['diskSize'],
        'diskType': context.properties['diskType'],
        'adminPassword': context.properties['adminPassword'],
        'runTimeConfigName': '$(ref.runtime_config.name)'
    }
