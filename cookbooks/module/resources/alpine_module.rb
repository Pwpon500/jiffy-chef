resource_name :alpine_module

property :mod, String, name_property: true

default_action :load

action :nothing do
end

action :load do
    file "/etc/modules-load.d/#{new_resource.mod}.conf" do
        content new_resource.mod
    end
    shell_out!("modprobe #{new_resource.mod}")
end

action :unload do
    file "/etc/modules-load.d/#{new_resource.mod}.conf" do
        content "blacklist #{new_resource.mod}"
    end
    shell_out!("modprobe -r #{new_resource.mod}")
end
