#!/opt/puppetlabs/puppet/bin/ruby

require_relative '../../ruby_task_helper/files/task_helper.rb'
require 'socket'
require 'cassandra'
require 'set'

class SetNodeData < TaskHelper
  def task(operation:,
           name: nil,
           type: 'bare',
           remote:  nil,
           ref: nil,
           **kwargs)

    cluster  = Cassandra.cluster(hosts: [Socket.gethostname])
    keyspace = 'puppet'
    @session = cluster.connect(keyspace) # create session, optionally scoped to a keyspace, to execute queries

    send(operation, name: name, type: type, remote: remote, ref: ref)
  end

  def list(opts)
    statement = @session.prepare('SELECT name, type, remote, ref FROM environments')
    list      = @session.execute(statement).to_a.map(&:compact)

    { 'environments' => list }
  end

  def add(opts)
    statement = @session.prepare(<<-CQL).bind([opts[:name], opts[:type], opts[:remote], opts[:ref]])
      INSERT INTO puppet.environments (name, type, remote, ref)
      VALUES (?, ?, ?, ?);
    CQL

    @session.execute(statement)

    # If we get this far, it worked!
    { 'add' => 'submitted' }
  end

  def modify(opts)
    set = opts.select { |key,val| [:type, :remote, :ref].include?(key) && !val.nil? }.keys

    statement = @session.prepare(<<-"CQL").bind(set.map { |key| opts[key] } << opts[:name])
      UPDATE puppet.environments
      SET #{set.map { |key| key.to_s + ' = ?' }.join(',')}
      WHERE name = ?;
    CQL

    results = @session.execute(statement)

    { 'modify' => 'submitted' }
  end

  def remove(opts)
    statement = @session.prepare(<<-CQL).bind([opts[:name]])
      DELETE FROM puppet.environments WHERE name = ?;
    CQL

    result = @session.execute(statement)

    # If we get this far, it probably worked?
    { 'removed' => result.size }
  end
end

if $PROGRAM_NAME == __FILE__
  SetNodeData.run
end
