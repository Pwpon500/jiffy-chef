resource_name :alpine_service
provides :service, platform: 'alpine'

property :service_name, String, name_property: true

property :runlevel, String, default: 'default'

default_action :nothing

action :nothing do
end

action :disable do
    shell_out!("rc-update del #{new_resource.service_name} #{new_resource.runlevel}")
end

action :enable do
    shell_out!("rc-update add #{new_resource.service_name} #{new_resource.runlevel}")
end

action :start do
    shell_out!("rc-service #{new_resource.service_name} start")
end

action :stop do
    shell_out!("rc-service #{new_resource.service_name} stop")
end

action :restart do
    shell_out!("rc-service #{new_resource.service_name} restart")
end
