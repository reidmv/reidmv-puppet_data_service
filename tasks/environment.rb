#!/opt/puppetlabs/puppet/bin/ruby

require_relative '../../ruby_task_helper/files/task_helper.rb'
require 'socket'
require 'cassandra'
require 'set'

class EnvironmentData < TaskHelper
  def task(operation:,
           name: nil,
           type: 'bare',
           source:  nil,
           version: nil,
           **kwargs)

    cluster  = Cassandra.cluster(hosts: [Socket.gethostname])
    keyspace = 'puppet'
    @session = cluster.connect(keyspace) # create session, optionally scoped to a keyspace, to execute queries

    send(operation, name: name, type: type, source: source, version: version)
  end

  def list(opts)
    statement = @session.prepare('SELECT name, type, source, version FROM environments')
    list      = @session.execute(statement).to_a.map(&:compact)

    { 'environments' => list }
  end

  def add(opts)
    statement = @session.prepare(<<-CQL).bind([opts[:name], opts[:type], opts[:source], opts[:version]])
      INSERT INTO environments (name, type, source, version)
      VALUES (?, ?, ?, ?);
    CQL

    @session.execute(statement)

    # If we get this far, it worked!
    { 'add' => 'submitted' }
  end

  def modify(opts)
    set = opts.select { |key,val| [:type, :source, :version].include?(key) && !val.nil? }.keys

    statement = @session.prepare(<<-"CQL").bind(set.map { |key| opts[key] } << opts[:name])
      UPDATE environments
      SET #{set.map { |key| key.to_s + ' = ?' }.join(',')}
      WHERE name = ?;
    CQL

    results = @session.execute(statement)

    { 'modify' => 'submitted' }
  end

  def remove(opts)
    statement = @session.prepare(<<-CQL).bind([opts[:name]])
      DELETE FROM environments WHERE name = ?;
    CQL

    result = @session.execute(statement)

    # If we get this far, it probably worked?
    { 'removed' => result.size }
  end
end

if $PROGRAM_NAME == __FILE__
  EnvironmentData.run
end
