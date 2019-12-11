#!/opt/puppetlabs/puppet/bin/ruby

require_relative "../../ruby_task_helper/files/task_helper.rb"
require 'socket'
require 'cassandra'
require 'json'


class ShowNode < TaskHelper
  def task(certname:, **kwargs)
    cluster = Cassandra.cluster(hosts: [Socket.gethostname])

    keyspace = 'puppet'
    session  = cluster.connect(keyspace) # create session, optionally scoped to a keyspace, to execute queries

    statement = session.prepare('SELECT * FROM nodedata WHERE certname=?').bind([certname])
    future = session.execute_async(statement)

    future.on_success do |rows|
      rows.first.to_json # Just return the first row
    end

    future.join
  end
end

