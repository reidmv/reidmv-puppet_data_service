#!/opt/puppetlabs/puppet/bin/ruby

require_relative '../../ruby_task_helper/files/task_helper.rb'
require 'socket'
require 'cassandra'
require 'json'

class ShowHieraLevel < TaskHelper
  def task(level:, **_kwargs)
    cluster = Cassandra.cluster(hosts: [Facter.value('ipaddress')])

    keyspace = 'puppet'
    session  = cluster.connect(keyspace) # create session, optionally scoped to a keyspace, to execute queries

    statement = session.prepare('SELECT * FROM hieradata WHERE level=?').bind([level])
    result    = session.execute(statement)

    hash = result.to_a.map { |row|
      [row['key'], JSON.parse(row['value'])]
    }.to_h

    { 'data' => hash }
  end
end

if $PROGRAM_NAME == __FILE__
  ShowHieraLevel.run
end
