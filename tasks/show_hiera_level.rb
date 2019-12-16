#!/opt/puppetlabs/puppet/bin/ruby

require_relative "../../ruby_task_helper/files/task_helper.rb"
require 'socket'
require 'cassandra'
require 'json'

class ShowHieraLevel < TaskHelper
  def task(level:, **kwargs)
    cluster = Cassandra.cluster(hosts: [Socket.gethostname])

    keyspace = 'puppet'
    session  = cluster.connect(keyspace) # create session, optionally scoped to a keyspace, to execute queries

    statement = session.prepare('SELECT * FROM hieradata WHERE level=?').bind([level])
    result    = session.execute(statement)

    hash = result.to_a.map do |row|
      [row['key'], JSON.parse(row['value'])]
    end.to_h

    {'data' => hash}
  end
end

if __FILE__ == $0
    ShowHieraLevel.run
end
