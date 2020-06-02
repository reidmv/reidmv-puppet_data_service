#!/bin/sh

# Puppet Task Name: uninstall_pds
#
# This is where you put the shell code for your task.
#
# You can write Puppet tasks in any language you want and it's easy to
# adapt an existing Python, PowerShell, Ruby, etc. script. Learn more at:
# https://puppet.com/docs/bolt/0.x/writing_tasks.html
#
# Puppet tasks make it easy for you to enable others to use your script. Tasks
# describe what it does, explains parameters and which are required or optional,
# as well as validates parameter type. For examples, if parameter "instances"
# must be an integer and the optional "datacenter" parameter must be one of
# portland, sydney, belfast or singapore then the .json file
# would include:
#   "parameters": {
#     "instances": {
#       "description": "Number of instances to create",
#       "type": "Integer"
#     },
#     "datacenter": {
#       "description": "Datacenter where instances will be created",
#       "type": "Enum[portland, sydney, belfast, singapore]"
#     }
#   }
# Learn more at: https://puppet.com/docs/bolt/0.x/writing_tasks.html#ariaid-title11
#

# Stop the Puppet agent and Puppet Server
/opt/puppetlabs/puppet/bin/puppet resource service puppet ensure=stopped
/opt/puppetlabs/puppet/bin/puppet resource service pe-puppetserver ensure=stopped

# Check for the trusted external command setting in puppet.conf
file_line='trusted_external_command = /etc/puppetlabs/puppet/get-nodedata.rb'
sed_pattern='trusted_external_command = \/etc\/puppetlabs\/puppet\/get-nodedata.rb'
if grep -q "${file_line}" "${PT_puppet_conf}"; then
    sed -i "/${sed_pattern}/d" "${PT_puppet_conf}"
fi
if grep -q "${file_line}" "${PT_puppet_conf}"; then
    # File line still present, start services and fail
    /opt/puppetlabs/puppet/bin/puppet resource service puppet ensure=running
    /opt/puppetlabs/puppet/bin/puppet resource service pe-puppetserver ensure=running
    exit 1
fi
# File line is gone, start services
/opt/puppetlabs/puppet/bin/puppet resource service puppet ensure=running
/opt/puppetlabs/puppet/bin/puppet resource service pe-puppetserver ensure=running