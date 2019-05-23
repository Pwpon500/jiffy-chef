#
# Cookbook:: dmvpn
# Recipe:: default
#
# Copyright:: 2018, The Authors, All Rights Reserved.

id = node['id']
id ||= node['interfaces']['eth0']['addr']

sysctl_param 'net.ipv4.ip_forward' do
    value 1
end

packages = %w[bird@testing opennhrp ipsec-tools iproute2]
packages.each do |pk|
    package pk
end

services = %w[bird opennhrp racoon]
services.each do |srv|
    service srv do
        action :enable
    end
end

modules = %w[ip_gre]
modules.each do |mod|
    alpine_module mod
end

if node.role?('dmvpn-hub')
    template '/etc/opennhrp/opennhrp.conf' do
        source 'opennhrp.conf.erb'
        variables(
            role: 'dmvpn-hub'
        )
        cookbook 'dmvpn'
        notifies :restart, 'service[opennhrp]'
    end
elsif node.role?('dmvpn-client')
    cisco = node['dmvpn']['is_cisco']
    cisco ||= false

    template '/etc/opennhrp/opennhrp.conf' do
        source 'opennhrp.conf.erb'
        variables(
            map: node['dmvpn']['map'],
            hub_ip: node['dmvpn']['hub_ip'],
            cisco: cisco,
            role: 'dmvpn-client'
        )
        cookbook 'dmvpn'
        notifies :restart, 'service[opennhrp]'
    end
end

directory '/etc/racoon'

template '/etc/racoon/racoon.conf' do
    source 'racoon.conf.erb'
    variables(
        id: id
    )
    cookbook 'dmvpn'
    notifies :restart, 'service[racoon]'
end

if node.role?('dmvpn-hub')
    clients = data_bag('dmvpn_keys')
    psk_hash = {}
    clients.each do |identifier|
        client = data_bag_item('dmvpn_keys', identifier)
        psk_hash[identifier] = client['psk']
    end

    template '/etc/racoon/psk.txt' do
        source 'psk.txt.erb'
        variables(
            clients: psk_hash
        )
        mode '400'
        cookbook 'dmvpn'
        notifies :restart, 'service[racoon]'
    end
elsif node.role?('dmvpn-client')
    client = data_bag_item('dmvpn_keys', id)
    psk_hash = { node['dmvpn']['hub_ip'] => client['psk'] }

    template '/etc/racoon/psk.txt' do
        source 'psk.txt.erb'
        variables(
            clients: psk_hash
        )
        mode '400'
        cookbook 'dmvpn'
        notifies :restart, 'service[racoon]'
    end
end

template '/etc/ipsec.conf' do
    source 'ipsec.conf.erb'
    cookbook 'dmvpn'
    notifies :restart, 'service[racoon]'
end

template '/etc/bird.conf' do
    source 'bird.conf.erb'
    variables(
        gateway: node['interfaces']['eth0']['gateway'],
        routes: node['dmvpn']['routes'],
        id: id
    )
    cookbook 'dmvpn'
    notifies :restart, 'service[bird]'
end
