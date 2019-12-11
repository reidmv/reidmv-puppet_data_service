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
    future = session.execute_async(statement)

    future.on_success do |rows|
      rows.to_a.map do |row|
        [row['key'], row['value']]
      end.to_h
    end

    future.join
  end
end

