#!/opt/puppetlabs/puppet/bin/ruby

require_relative '../../ruby_task_helper/files/task_helper.rb'
require 'facter'
require 'cassandra'
require 'set'

class PuppetEnvironmentData < TaskHelper
  def task(op:,
           name: nil,
           type: nil,
           source:  nil,
           version: nil,
           **kwargs)

    cluster  = Cassandra.cluster(hosts: [Facter.value('ipaddress')])
    keyspace = 'puppet'
    @session = cluster.connect(keyspace) # create session, optionally scoped to a keyspace, to execute queries

    send(op, name: name, type: type, source: source, version: version)
  end

  def list(opts)
    opts[:type] ||= 'bare'
    statement = @session.prepare('SELECT name, type, source, version FROM puppet_environments')
    list      = @session.execute(statement).to_a.map(&:compact)

    { 'puppet_environments' => list }
  end

  def add(opts)
    statement = @session.prepare(<<-CQL).bind([opts[:name], opts[:type], opts[:source], opts[:version]])
      INSERT INTO puppet_environments (name, type, source, version)
      VALUES (?, ?, ?, ?);
    CQL

    @session.execute(statement)

    # If we get this far, it worked!
    { 'add' => 'submitted' }
  end

  def modify(opts)
    set = opts.select { |key,val| [:type, :source, :version].include?(key) && !val.nil? }.keys

    statement = @session.prepare(<<-"CQL").bind(set.map { |key| opts[key] } << opts[:name])
      UPDATE puppet_environments
      SET #{set.map { |key| key.to_s + ' = ?' }.join(',')}
      WHERE name = ?;
    CQL

    results = @session.execute(statement)

    { 'modify' => 'submitted' }
  end

  def remove(opts)
    statement = @session.prepare(<<-CQL).bind([opts[:name]])
      DELETE FROM puppet_environments WHERE name = ?;
    CQL

    result = @session.execute(statement)

    # If we get this far, it probably worked?
    { 'remove' => 'submitted' }
  end
end

if $PROGRAM_NAME == __FILE__
  PuppetEnvironmentData.run
end
