#!/opt/puppetlabs/puppet/bin/ruby

require_relative '../../ruby_task_helper/files/task_helper.rb'
require 'socket'
require 'cassandra'
require 'set'

class ShowNode < TaskHelper
  def task(certname:, **_kwargs)
    cluster = Cassandra.cluster(hosts: [Socket.gethostname])

    keyspace = 'puppet'
    session  = cluster.connect(keyspace) # create session, optionally scoped to a keyspace, to execute queries

    statement = session.prepare('SELECT * FROM nodedata WHERE certname=?').bind([certname])
    result    = session.execute(statement)

    data = result.first

    # Convert the Ruby Set object into an array
    data['classes'] = data.delete('classes').to_a unless data.nil? || data['classes'].nil?

    { 'node' => data }
  end
end

if $PROGRAM_NAME == __FILE__
  ShowNode.run
end
