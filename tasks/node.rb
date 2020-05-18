#!/opt/puppetlabs/puppet/bin/ruby

require_relative '../../ruby_task_helper/files/task_helper.rb'
require 'facter'
require 'puppet_data_service'

class NodeData < TaskHelper
  def task(op:, **kwargs)
    @session = PuppetDatabaseService.connect(database: Facter.value['pds_database'],
                                             hosts: Facter.value['ipaddress'])
    @target = 'module'
    return @session.execute(op, @target, **kwargs)
  end
end

if $PROGRAM_NAME == __FILE__
  NodeData.run
end
