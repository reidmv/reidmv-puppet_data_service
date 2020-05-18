#!/opt/puppetlabs/puppet/bin/ruby

require_relative '../../ruby_task_helper/files/task_helper.rb'
require 'facter'
require 'puppet_data_service'

class PuppetEnvironmentData < TaskHelper
  def task(op:,
           name: nil,
           type: nil,
           source:  nil,
           version: nil,
           **kwargs)

    @session = PuppetDatabaseService.connect(database: Facter.value['pds_database'],
                                             hosts: Facter.value['ipaddress'])
    @target = 'module'
    return @session.execute(op, @target, name: name, type: type, source: source, version: version)
  end
end

if $PROGRAM_NAME == __FILE__
  PuppetEnvironmentData.run
end
