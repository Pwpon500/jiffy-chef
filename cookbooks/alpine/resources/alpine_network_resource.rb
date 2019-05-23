resource_name :alpine_network_resource
provides :network_interface, platform: 'alpine'

property :device, String, name_property: true

property :interfaces, Hash, required: true

default_action :create

action :create do
    template '/etc/network/interfaces' do
        source 'interfaces.erb'
        cookbook 'alpine'
        variables(
            interface_hash: new_resource.interfaces
        )
    end
end

action :nothing do
end
