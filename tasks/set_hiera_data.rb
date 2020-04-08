#!/opt/puppetlabs/puppet/bin/ruby

require_relative '../../ruby_task_helper/files/task_helper.rb'
require 'facter'
require 'cassandra'
require 'json'

class SetHieraData < TaskHelper
  def task(level:,
           data:,
           **_kwargs)

    cluster = Cassandra.cluster(hosts: [Facter.value('ipaddress')])

    keyspace = 'puppet'
    session  = cluster.connect(keyspace) # create session, optionally scoped to a keyspace, to execute queries

    statement = session.prepare(<<-CQL)
      INSERT INTO puppet.hieradata (level, key, value)
      VALUES (?, ?, ?);
    CQL

    futures = data.map do |key, value|
      session.execute_async(statement, arguments: [level, key.to_s, value.to_json])
    end

    { 'upserted' => futures.map(&:join).size }
  end
end

if $PROGRAM_NAME == __FILE__
  SetHieraData.run
end
