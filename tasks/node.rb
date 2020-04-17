#!/opt/puppetlabs/puppet/bin/ruby

require_relative '../../ruby_task_helper/files/task_helper.rb'
require 'facter'
require 'cassandra'
require 'set'

class NodeData < TaskHelper
  def task(op:,
           name: nil,
           release: nil,
           classes:  nil,
           userdata: nil,
           **kwargs)

    cluster  = Cassandra.cluster(hosts: [Facter.value('ipaddress')])
    keyspace = 'puppet'
    @session = cluster.connect(keyspace) # create session, optionally scoped to a keyspace, to execute queries

    send(op, name: name, release: release, classes: classes, userdata: userdata)
  end

  def list(opts)
    statement = @session.prepare('SELECT name FROM nodedata')
    data      = @session.execute(statement)

    { 'nodes' => data.rows.map { |row| row['name'] } }
  end

  def show(opts)
    statement = @session.prepare('SELECT * FROM nodedata WHERE name = ?').bind([opts[:name]])
    data      = @session.execute(statement).first

    # Convert the Ruby Set object into an array
    data['classes'] = data.delete('classes').to_a unless data.nil? || data['classes'].nil?
    data['userdata'] = JSON.parse(data.delete('userdata')) unless data.nil? || data['userdata'].nil?

    { 'node' => data }
  end

  def add(opts)
    statement = @session.prepare(<<-CQL)
      INSERT INTO nodedata (name, release, classes, userdata)
      VALUES (?, ?, ?, ?);
    CQL

    @session.execute(statement.bind([opts[:name],
                                     opts[:release],
                                     opts[:classes].to_set,
                                     opts[:userdata].to_json]))

    # If we get this far, it worked!
    { 'add' => 'submitted' }
  end

  def modify(opts)
    set = opts.select { |key,val| [:release, :classes, :userdata].include?(key) && !val.nil? }.keys
    set['classes'] = opts.delete('classes').to_set if set['classes']
    set['userdata'] = opts.delete('userdata').to_json if set['userdata']

    statement = @session.prepare(<<-"CQL").bind(set.map { |key| opts[key] } << opts[:name])
      UPDATE nodedata
      SET #{set.map { |key| key.to_s + ' = ?' }.join(',')}
      WHERE name = ?;
    CQL

    results = @session.execute(statement)

    { 'modify' => 'submitted' }
  end

  def remove(opts)
    statement = @session.prepare(<<-CQL).bind([opts[:name]])
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
