def generate_config(context):
    prefix = context.env['deployment']
    instance_template_name = prefix + '-cluster-it'
    standalone_instance_template_name = prefix + '-standalone-it'
    igm_name = prefix + '-cluster' + '-igm'
    standalone_igm_name = prefix + '-standalone' + '-igm'
    region = context.properties['zone'][:-2]
    network = {
        'name': 'network',
        'type': 'network.py',
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
    config['resources'].append(network)
    config['resources'].append(firewall)

    if context.properties['nodeCount'] > 1:

        instance_group = {
            'name': 'instance-group',
            'type': 'instance_group.py',
            'metadata': {
                'dependsOn': ['network'],
            },
            'properties': instance_group_properties(context, igm_name, instance_template_name, region)
        }
        config['resources'].append(instance_group)

        loadbalancer = {
            'name': 'loadbalancer',
            'type': 'loadbalancer.py',
            'properties': {
                'instance_group': '$(ref.instance-group.name)',
                'region': region,
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

        config['resources'].append(instance_group)
        config['resources'].append(public_ip_addresss)

        config['outputs'].append({
            'name': 'ip',
            'value': '$(ref.standalone-ip-address.ip)'
        })
    return config


def instance_group_properties(context, igm_name, instance_template_name, region, public_ip=''):
    return {
        'region': region,
        'zone': context.properties['zone'],
        'publicIp': public_ip,
        'networkRef': '$(ref.network.networkRef)',
        'subnetRef': '$(ref.network.subnetRef)',
        'instanceTemplateName': instance_template_name,
        'instanceGroupManagerName': igm_name,
        'nodeCount': context.properties['nodeCount'],
        'nodeType': context.properties['nodeType'],
        'diskSize': context.properties['diskSize'],
        'diskType': context.properties['diskType'],
        'adminPassword': context.properties['adminPassword'],
        'graphDatabaseVersion': context.properties['graphDatabaseVersion'],
        'installGraphDataScience': context.properties['installGraphDataScience'],
        'graphDataScienceLicenseKey': context.properties['graphDataScienceLicenseKey'],
        'installBloom': context.properties['installBloom'],
        'bloomLicenseKey': context.properties['bloomLicenseKey']
    }
