#!/opt/puppetlabs/puppet/bin/ruby

require_relative '../../ruby_task_helper/files/task_helper.rb'
require 'facter'
require 'puppet_data_service'

class EnvironmentData < TaskHelper
  def task(op:,
           level: nil,
           data: nil,
           keys: nil,
           **kwargs)

    # create session, optionally scoped to a keyspace, to execute queries
    @session = PuppetDatabaseService.connect(database: Facter.value['pds_database'],
                                             hosts: Facter.value['ipaddress'])
    @target = 'hiera'

    return @session.execute(op, @target, level: level, data: data, keys: keys)
  end
end

if $PROGRAM_NAME == __FILE__
  EnvironmentData.run
end
