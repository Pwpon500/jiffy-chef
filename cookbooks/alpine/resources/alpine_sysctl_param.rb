resource_name :alpine_sysctl_param
provides :sysctl_param, platform: 'alpine'

property :param_name, String, name_property: true
property :value, [String, Integer], required: true

default_action :apply

action :nothing do
end

action :apply do
    template "/etc/sysctl.d/#{new_resource.param_name}.conf" do
        source 'sysctl.conf.erb'
        variables(
            param: new_resource.param_name,
            value: new_resource.value
        )
        cookbook 'alpine'
    end

    shell_out('sysctl -p')
end
