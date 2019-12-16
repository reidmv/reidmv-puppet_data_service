#!/opt/puppetlabs/puppet/bin/ruby

require_relative "../../ruby_task_helper/files/task_helper.rb"
require 'socket'
require 'cassandra'
require 'set'

class SetNodeData < TaskHelper
  def task(certname:,
           environment:,
           release:,
           classes: [ ],
           **kwargs)

    cluster = Cassandra.cluster(hosts: [Socket.gethostname])

    keyspace = 'puppet'
    session  = cluster.connect(keyspace) # create session, optionally scoped to a keyspace, to execute queries

    statement = session.prepare(<<-CQL).bind([certname, environment, release, classes.to_set])
      INSERT INTO puppet.nodedata (certname, environment, release, classes) 
      VALUES (?, ?, ?, ?);
    CQL

    session.execute(statement)

    # If we get this far, it worked!
    { 'upserted' => 1 }
  end
end

if __FILE__ == $0
    SetNodeData.run
end
