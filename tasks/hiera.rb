#!/opt/puppetlabs/puppet/bin/ruby

require_relative '../../ruby_task_helper/files/task_helper.rb'
require 'facter'
require 'cassandra'

class EnvironmentData < TaskHelper
  def task(operation:,
           level: nil,
           data: nil,
           keys: nil,
           **kwargs)

    cluster  = Cassandra.cluster(hosts: [Facter.value('ipaddress')])
    keyspace = 'puppet'
    @session = cluster.connect(keyspace) # create session, optionally scoped to a keyspace, to execute queries

    send(operation, level: level, data: data, keys: keys)
  end

  def list(opts)
    statement = @session.prepare('SELECT DISTINCT level FROM hieradata')
    data      = @session.execute(statement).to_a.map(&:compact)

    { 'levels' => data.map { |row| row['level'] } }
  end

  def show(opts)
    statement = @session.prepare('SELECT key,value FROM hieradata where level = ?').bind([opts[:level]])
    data      = @session.execute(statement)

    data.rows.map { |row| {row['key'] => row['value']} }.reduce({}, :merge)
  end

  def set(opts)
    statement = @session.prepare(<<-CQL)
      INSERT INTO hieradata (level, key, value)
      VALUES (?, ?, ?);
    CQL

    futures = opts[:data].map do |key, value|
      @session.execute_async(statement, arguments: [opts[:level], key.to_s, value.to_json])
    end

    { 'set' => futures.map(&:join).size }
  end

  def unset(opts)
    statement = @session.prepare(<<-CQL)
      DELETE FROM hieradata WHERE level = ? AND key = ?;
    CQL

    futures = opts[:keys].map do |key|
      @session.execute_async(statement, arguments: [opts[:level], key.to_s])
    end

    { 'unset' => futures.map(&:join).size }
  end
end

if $PROGRAM_NAME == __FILE__
  EnvironmentData.run
end
