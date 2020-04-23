#!/opt/puppetlabs/puppet/bin/ruby

require_relative '../../ruby_task_helper/files/task_helper.rb'
require 'facter'
require 'cassandra'
require 'set'

class NodeData < TaskHelper
  def task(op:, **kwargs)
    cluster  = Cassandra.cluster(hosts: [Facter.value('ipaddress')])
    keyspace = 'puppet'
    @session = cluster.connect(keyspace) # create session, optionally scoped to a keyspace, to execute queries

    send(op, **kwargs)
  end

  def list(**kwargs)
    statement = @session.prepare('SELECT name FROM nodedata')
    data      = @session.execute(statement)

    { 'nodes' => data.rows.map { |row| row['name'] } }
  end

  def show(name:, **kwargs)
    statement = @session.prepare('SELECT * FROM nodedata WHERE name = ?').bind([name])
    data      = @session.execute(statement).first

    # Convert the Ruby Set object into an array
    data['puppet_classes'] = data.delete('puppet_classes').to_a unless data.nil? || data['puppet_classes'].nil?
    data['userdata'] = JSON.parse(data.delete('userdata')) unless data.nil? || data['userdata'].nil?

    { 'node' => data }
  end

  def add(name:, puppet_environment: nil, puppet_classes: [], userdata: {}, **kwargs)
    statement = @session.prepare(<<-CQL)
      INSERT INTO nodedata (name, puppet_environment, puppet_classes, userdata)
      VALUES (?, ?, ?, ?);
    CQL

    @session.execute(statement.bind([name, puppet_environment, puppet_classes.to_set, userdata.to_json]))

    # If we get this far, it worked!
    { 'add' => 'submitted' }
  end

  def modify(**kwargs)
    set = kwargs.select { |key,val| [:puppet_environment, :puppet_classes, :userdata].include?(key) && !val.nil? }
    set[:puppet_classes] = set.delete(:puppet_classes).to_set if set[:puppet_classes]
    set[:userdata] = set.delete(:userdata).to_json if set[:userdata]

    ordered_keys = set.keys
    statement = @session.prepare(<<-"CQL").bind(ordered_keys.map { |key| set[key] } << kwargs[:name])
      UPDATE nodedata
      SET #{ordered_keys.map { |key| key.to_s + ' = ?' }.join(',')}
      WHERE name = ?;
    CQL

    results = @session.execute(statement)

    { 'modify' => 'submitted' }
  end

  def remove(name:, **kwargs)
    statement = @session.prepare(<<-CQL).bind([name])
      DELETE FROM nodedata WHERE name = ?;
    CQL

    result = @session.execute(statement)

    # If we get this far, it probably worked?
    { 'remove' => 'submitted' }
  end
end

if $PROGRAM_NAME == __FILE__
  NodeData.run
end
