#!/opt/puppetlabs/puppet/bin/ruby

require_relative '../../ruby_task_helper/files/task_helper.rb'
require 'facter'
require 'cassandra'
require 'set'

class ModuleData < TaskHelper
  def task(operation:,
           environment:,
           name: nil,
           type: nil,
           source:  nil,
           version: nil,
           **kwargs)

    cluster  = Cassandra.cluster(hosts: [Facter.value('ipaddress')])
    keyspace = 'puppet'
    @session = cluster.connect(keyspace) # create session, optionally scoped to a keyspace, to execute queries

    send(operation, environment: environment, name: name, type: type, source: source, version: version)
  end

  def list(opts)
    statement = @session.prepare(<<-CQL).bind([opts[:environment]])
      SELECT modules FROM environments
      WHERE name = ?
    CQL

    result = @session.execute(statement).first

    case 
    when result.nil?
      'no such environment'
    when result['modules'].nil?
      { 'modules' => [] }
    else
      { 'modules' => result['modules'].map { |key,val| [key, JSON.parse(val)] }.to_h }
    end
  end

  def add(opts)
    moddata = [:type, :version, :source].map { |key| [key.to_s, opts[key]] }.to_h.compact.to_json

    statement = @session.prepare(<<-CQL).bind([opts[:name], moddata, opts[:environment]])
      UPDATE environments
      SET modules[?] = ?
      WHERE name = ?;
    CQL

    @session.execute(statement)

    # If we get this far, it worked!
    { 'add' => 'submitted' }
  end

  def modify(opts)
    # Retrieve the current value of the module from the environment
    select = @session.prepare(<<-CQL).bind([opts[:environment]])
      SELECT modules FROM environments
      WHERE name = ?;
    CQL

    # TODO: deal with what happens when nothing comes back
    current = @session.execute(select).first['modules'][opts[:name]]

    # Determine which keys will be updated for the module
    update = opts.select { |key,val| [:type, :source, :version].include?(key) && !val.nil? }
    new = JSON.parse(current).merge(update.map { |key,val| [key.to_s, val] }.to_h)

    update = @session.prepare(<<-"CQL").bind([opts[:name], new.to_json, opts[:environment]])
      UPDATE environments
      SET modules[?] = ?
      WHERE name = ?;
    CQL

    result = @session.execute(update)

    { 'modify' => 'submitted' }
  end

  def remove(opts)
    statement = @session.prepare(<<-CQL).bind([opts[:name], opts[:environment]])
      DELETE modules[?] FROM environments WHERE name = ?;
    CQL

    result = @session.execute(statement)

    # If we get this far, it probably worked?
    { 'remove' => 'submitted'  }
  end
end

if $PROGRAM_NAME == __FILE__
  ModuleData.run
end
