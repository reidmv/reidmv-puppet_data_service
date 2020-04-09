#!/opt/puppetlabs/puppet/bin/ruby

require_relative '../../ruby_task_helper/files/task_helper.rb'
require 'facter'
require 'cassandra'
require 'json'

class DeleteHieraData < TaskHelper
  def task(level:,
           keys:,
           **_kwargs)

    cluster = Cassandra.cluster(hosts: [Facter.value('ipaddress')])

    keyspace = 'puppet'
    session  = cluster.connect(keyspace) # create session, optionally scoped to a keyspace, to execute queries

    statement = session.prepare(<<-CQL)
      DELETE FROM puppet.hieradata WHERE level = ? AND key = ?;
    CQL

    futures = keys.map do |key|
      session.execute_async(statement, arguments: [level, key.to_s])
    end

    { 'applied' => futures.map(&:join).size }
  end
end

if $PROGRAM_NAME == __FILE__
  DeleteHieraData.run
end
