#!/opt/puppetlabs/puppet/bin/ruby

require_relative '../../ruby_task_helper/files/task_helper.rb'
require 'facter'
require 'cassandra'
require 'set'

class ModuleData < TaskHelper
  def task(op:,
           environment:,
           name: nil,
           type: nil,
           source:  nil,
           version: nil,
           **kwargs)

    cluster  = Cassandra.cluster(hosts: [Facter.value('ipaddress')])
    keyspace = 'puppet'
    @session = cluster.connect(keyspace) # create session, optionally scoped to a keyspace, to execute queries

    send(op, environment: environment, name: name, type: type, source: source, version: version)
  end

  def list(opts)
    statement = @session.prepare(<<-CQL).bind([opts[:environment]])
      SELECT * FROM modules
      WHERE environment = ?
    CQL

    result = @session.execute(statement)

    if result.size == 0
      "no modules for environment #{opts[:environment]}"
    else
      result.to_a.map { |mod| [mod.delete('name'), mod] }.to_h
    end
  end

  def add(opts)
    binding = [opts[:environment], opts[:name], opts[:type], opts[:source], opts[:version]]
    statement = @session.prepare(<<-CQL).bind(*binding)
      INSERT INTO modules (environment, name, type, source, version)
      VALUES (?, ?, ?, ?, ?)
    CQL

    @session.execute(statement)

    # If we get this far, it worked!
    { 'add' => 'submitted' }
  end

  def modify(opts)
    # Determine which keys will be updated for the module
    set = opts.select { |key,val| [:type, :source, :version].include?(key) && !val.nil? }.keys

    update = @session.prepare(<<-"CQL").bind(set.map { |key| opts[key] } << opts[:environment] << opts[:name])
      UPDATE modules
      SET #{set.map { |key| key.to_s + ' = ?' }.join(',')}
      WHERE environment = ? AND name = ?;
    CQL

    result = @session.execute(update)

    { 'modify' => 'submitted' }
  end

  def remove(opts)
    statement = @session.prepare(<<-CQL).bind([opts[:environment], opts[:name]])
      DELETE FROM modules WHERE environment = ? AND name = ?;
    CQL

    result = @session.execute(statement)

    # If we get this far, it probably worked?
    { 'remove' => 'submitted'  }
  end
end

if $PROGRAM_NAME == __FILE__
  ModuleData.run
end
