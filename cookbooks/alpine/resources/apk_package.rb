resource_name :apk_package
provides :package, platform: 'alpine'

property :package_name, String, name_property: true

property :repository, String
property :allow_untrusted, [true, false], default: false
property :use_cache, [true, false], default: true
property :purge, [true, false], default: false

default_action :install

action :install do
    shell_out!("apk add #{new_resource.package_name} #{generate_args}")
end

action :upgrade do
    shell_out!("apk add --upgrade #{new_resource.package_name} #{generate_args}")
end

action :nothing do
end

action :remove do
    shell_out!("apk del #{new_resource.package_name} #{generate_args}")
end

action :fetch do
    shell_out!("apk fetch #{new_resource.package_name} #{generate_args}")
end

action_class do
    def generate_args
        args = ''
        args += "-X #{new_resource.repository} " unless property_is_set?(:repository)
        args += '--allow-untrusted ' if new_resource.allow_untrusted
        args += '--no-cache ' unless new_resource.use_cache
        args += '--purge ' if new_resource.purge
        args
    end
end
