#
# Cookbook:: webserver
# Recipe:: default
#
# Copyright:: 2018, The Authors, All Rights Reserved.

package 'nginx'
package 'keepalived'

directory '/etc/keepalived/conf.d'

service 'nginx' do
    action :enable
end

service 'nginx' do
    action :start
end

service 'keepalived' do
    action :enable
end

service 'keepalived' do
    action :start
end

if node.role? 'load-balancer'
    upstream_bag_name = node['load-balancer']['upstream_bag']
    upstream_bag_name ||= 'srv_upstreams'
    upstreams = data_bag_item(upstream_bag_name, node['load-balancer']['upstream_item'])['hosts']
    template '/etc/nginx/nginx.conf' do
        source 'load-balancer.conf.erb'
        variables(
            server_name: node['webserver']['server_name'],
            upstreams: upstreams
        )
        notifies :restart, "service[nginx]"
    end
end

if node.role? 'webserver'
    directory '/var/www/html' do
        recursive true
        action :delete
        not_if { File.exist? '/var/www/html/.git' }
    end

    git '/var/www/html' do
        repository node['webserver']['repo']
    end

    template '/etc/nginx/nginx.conf' do
        source 'webserver.conf.erb'
        variables(
            server_name: node['webserver']['server_name']
        )
        notifies :restart, "service[nginx]"
    end
end


file '/etc/keepalived/keepalived.conf' do
    content 'include /etc/keepalived/conf.d/*'
end

keepalived_global_defs 'global_defs' do
    router_id node.name
end

keepalived_vrrp_script 'chk_nginx' do
    interval 2
    weight 50
    script '"/usr/bin/killall -0 nginx"'
end

keepalived_vrrp_instance 'srv_vip' do
    master node['webserver']['master']
    interface 'eth0'
    virtual_router_id 51
    priority 101
    virtual_ipaddress [node['webserver']['vip']]
    authentication auth_type: 'PASS', auth_pass: node['webserver']['auth_pass']
end
