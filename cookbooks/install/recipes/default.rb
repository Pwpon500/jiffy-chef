#
# Cookbook:: install
# Recipe:: default
#
# Copyright:: 2017, The Authors, All Rights Reserved.

packages = ['vim', 'fish', 'figlet', 'vlan', 'bridge-utils', 'tcpdump', 'mdadm', 'ncftp', 'git', 'openssh-server', 'bash']
alpine_packages = ['ruby-dev', 'build-base', 'shadow']

packages += alpine_packages if node['platform'] == 'alpine'

execute 'apt update' do
    command 'apt update'
    only_if { node['platform'].include?('debian') }
end

execute 'apk update' do
    command 'apk update'
    only_if { node['platform'].include?('alpine') }
end

package 'git'
directory '/opt'

# actual conf files and scripts
git '/opt/srv-conf' do
    repository 'https://github.com/Pwpon500/srv-conf'
end

remote_file '/etc/apt/sources.list' do
    path '/etc/apt/sources.list'
    source 'file:///opt/srv-conf/rc/apt_repos'
    only_if { node['platform'].include?('debian') }
end

remote_file '/etc/apk/repositories' do
    path '/etc/apk/repositories'
    source 'file:///opt/srv-conf/rc/apk_repos'
    only_if { node['platform'].include?('alpine') }
end

execute 'apt update' do
    command 'apt update'
    only_if { node['platform'].include?('debian') }
end

execute 'apk update' do
    command 'apk update'
    only_if { node['platform'].include?('alpine') }
end

hostname node.name

# loop through packages and install/upgrade them
packages.each do |pk|
    package pk
end

# install chef gems
chef_gem 'ruby-shadow'

# set passwords
user 'root' do
    password node['shadow']
end
user 'sysadmin' do
    password node['shadow']
end

# setup network interfaces
if node['platform'] == 'alpine'
    network_interface 'interfaces' do
        interfaces node['interfaces']
    end
else
    node['interfaces'].each do |int, props|
        network_interface int do
            bootproto props['proto']
            address props['addr'] if props.key?('addr')
            netmask props['netmask'] if props.key?('netmask')
            gateway props['gateway'] if props.key?('gateway')
        end
    end
end

# remove other motds
directory '/etc/update-motd.d' do
    recursive true
    action :delete
end

# create all required directories
directories = ['/etc/update-motd.d', '/root/.config/fish', '/root/.vim/bundle']

directories.each do |path|
    directory path do
        recursive true
    end
end

# references to conf files
refs = {
    '/root/.vimrc' => 'source /opt/srv-conf/rc/vimrc',
    '/root/.config/fish/config.fish' => 'source /opt/srv-conf/rc/config.fish',
    '/root/.bashrc' => '. /opt/srv-conf/rc/bashrc',
    '/root/.bash_aliases' => '. /opt/srv-conf/rc/bash_aliases',
    '/etc/motd' => ''
}

refs.each do |loc, cont|
    file loc do
        content cont
    end
end

# create all required links
links = {
    '/opt/srv-conf/scripts/20-updates' => '/etc/update-motd.d/20-updates',
    '/opt/srv-conf/rc/sshd_config' => '/etc/ssh/sshd_config'
}

links.each do |orig, ln|
    link ln do
        to orig
    end
end

# instantiate vundle
git '/root/.vim/bundle/Vundle.vim' do
    repository 'https://github.com/VundleVim/Vundle.vim.git'
end

execute 'start_vundle' do
    command '/usr/bin/vim +PluginInstall +qall'
end
