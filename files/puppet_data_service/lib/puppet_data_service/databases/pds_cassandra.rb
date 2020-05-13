require 'puppet_data_service/databases/pds_database'
require 'cassandra'
require 'json'
require 'set'

module PuppetDataService
    module Databases

        # Implements a Cassandra database backend
        # 
        # @param [Array] hosts
        # @param [String] keyspace
        class PdsCassandra < PdsDatabase

            def initialize(hosts:, keyspace: 'puppet')
                @hosts = hosts
                @keyspace = keyspace
                @cluster = Cassandra.cluster(hosts: hosts)
                begin
                    @session = @cluster.connect(@keyspace) # create session, optionally scoped to a keyspace, to execute queries
                rescue Cassandra::Error => e
                    raise PuppetDataService::Errors::ConnError.new(
                        'Could not connect to the Cassandra database!',
                        e,
                        dbtype: 'cassandra',
                        hosts: @hosts
                    )
                end
            end

            # TASK METHODS

            def list_hiera(kwargs)
                statement = @session.prepare('SELECT DISTINCT level FROM hieradata')
                data      = @session.execute(statement)

                { 'levels' => data.rows.map { |row| row['level'] } }
            end

            def get_hiera(kwargs)
                statement = @session.prepare('SELECT key,value FROM hieradata where level = ?').bind([kwargs[:level]])
                data      = @session.execute(statement)

                data.rows.map { |row| {row['key'] => row['value']} }.reduce({}, :merge)
            end

            def add_hiera(kwargs)
                statement = @session.prepare(<<-CQL)
                    INSERT INTO hieradata (level, key, value)
                    VALUES (?, ?, ?);
                CQL

                futures = kwargs[:data].map do |key, value|
                    @session.execute_async(statement, arguments: [kwargs[:level], key.to_s, value.to_json])
                end

                { 'set' => futures.map(&:join).size }
            end

            def remove_hiera(kwargs)
                statement = @session.prepare(<<-CQL)
                    DELETE FROM hieradata WHERE level = ? AND key = ?;
                CQL

                futures = kwargs[:keys].map do |key|
                    @session.execute_async(statement, arguments: [kwargs[:level], key.to_s])
                end

                { 'unset' => futures.map(&:join).size }
            end

            def list_module(kwargs)
                statement = @session.prepare(<<-CQL).bind([kwargs[:puppet_environment]])
                    SELECT modules FROM puppet_environments
                    WHERE name = ?
                CQL

                result = @session.execute(statement).first

                case 
                when result.nil?
                    'no such puppet_environment'
                when result['modules'].nil?
                    { 'modules' => [] }
                else
                    { 'modules' => result['modules'].map { |key,val| [key, JSON.parse(val)] }.to_h }
                end
            end

            def add_module(kwargs)
                moddata = [:type, :version, :source].map { |key| [key.to_s, kwargs[key]] }.to_h.compact.to_json

                statement = @session.prepare(<<-CQL).bind([kwargs[:name], moddata, kwargs[:puppet_environment]])
                    UPDATE puppet_environments
                    SET modules[?] = ?
                    WHERE name = ?;
                CQL

                @session.execute(statement)

                # If we get this far, it worked!
                { 'add' => 'submitted' }
            end

            def modify_module(kwargs)
                # Retrieve the current value of the module from the puppet_environment
                select = @session.prepare(<<-CQL).bind([kwargs[:puppet_environment]])
                    SELECT modules FROM puppet_environments
                    WHERE name = ?;
                CQL

                # TODO: deal with what happens when nothing comes back
                current = @session.execute(select).first['modules'][kwargs[:name]]

                # Determine which keys will be updated for the module
                update = kwargs.select { |key,val| [:type, :source, :version].include?(key) && !val.nil? }
                new = JSON.parse(current).merge(update.map { |key,val| [key.to_s, val] }.to_h)

                update = @session.prepare(<<-"CQL").bind([kwargs[:name], new.to_json, kwargs[:puppet_environment]])
                    UPDATE puppet_environments
                    SET modules[?] = ?
                    WHERE name = ?;
                CQL

                result = @session.execute(update)

                { 'modify' => 'submitted' }
            end

            def remove_module(kwargs)
                statement = @session.prepare(<<-CQL).bind([kwargs[:name], kwargs[:puppet_environment]])
                    DELETE modules[?] FROM puppet_environments WHERE name = ?;
                CQL

                result = @session.execute(statement)

                # If we get this far, it probably worked?
                { 'remove' => 'submitted'  }
            end

            def list_node(kwargs)
                statement = @session.prepare('SELECT name FROM nodedata')
                data      = @session.execute(statement)

                { 'nodes' => data.rows.map { |row| row['name'] } }
            end

            def get_node(kwargs)
                statement = @session.prepare('SELECT * FROM nodedata WHERE name = ?').bind([name])
                data      = @session.execute(statement).first

                # Convert the Ruby Set object into an array
                data['puppet_classes'] = data.delete('puppet_classes').to_a unless data.nil? || data['puppet_classes'].nil?
                data['userdata'] = JSON.parse(data.delete('userdata')) unless data.nil? || data['userdata'].nil?

                { 'node' => data }
            end

            def add_node(kwargs)
                statement = @session.prepare(<<-CQL)
                    INSERT INTO nodedata (name, puppet_environment, puppet_classes, userdata)
                    VALUES (?, ?, ?, ?);
                CQL

                @session.execute(statement.bind([name, puppet_environment, puppet_classes.to_set, userdata.to_json]))

                # If we get this far, it worked!
                { 'add' => 'submitted' }
            end

            def modify_node(kwargs)
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

            def remove_node(kwargs)
                statement = @session.prepare(<<-CQL).bind([name])
                    DELETE FROM nodedata WHERE name = ?;
                CQL

                result = @session.execute(statement)

                # If we get this far, it probably worked?
                { 'remove' => 'submitted' }
            end

            def list_puppet_environment(kwargs)
                opts[:type] ||= 'bare'
                statement = @session.prepare('SELECT name, type, source, version FROM puppet_environments')
                list      = @session.execute(statement).to_a.map(&:compact)

                { 'puppet_environments' => list }
            end

            def add_puppet_environment(kwargs)
                statement = @session.prepare(<<-CQL).bind([opts[:name], opts[:type], opts[:source], opts[:version]])
                    INSERT INTO puppet_environments (name, type, source, version)
                    VALUES (?, ?, ?, ?);
                CQL

                @session.execute(statement)

                # If we get this far, it worked!
                { 'add' => 'submitted' }
            end

            def modify_puppet_environment(kwargs)
                set = opts.select { |key,val| [:type, :source, :version].include?(key) && !val.nil? }.keys

                statement = @session.prepare(<<-"CQL").bind(set.map { |key| opts[key] } << opts[:name])
                    UPDATE puppet_environments
                    SET #{set.map { |key| key.to_s + ' = ?' }.join(',')}
                    WHERE name = ?;
                CQL

                results = @session.execute(statement)

                { 'modify' => 'submitted' }
            end

            def remove_puppet_environment(kwargs)
                statement = @session.prepare(<<-CQL).bind([opts[:name]])
                    DELETE FROM puppet_environments WHERE name = ?;
                CQL

                result = @session.execute(statement)

                # If we get this far, it probably worked?
                { 'remove' => 'submitted' }
            end

            # SCRIPT METHODS

            def get_nodedata(kwargs)
                statement = @session.prepare('SELECT json puppet_environment,puppet_classes,userdata FROM nodedata WHERE name = ?').bind([kwargs['certname']])
                result    = @session.execute(statement)
            
                if result.first.nil?
                    return {}
                else
                    return { 'nodedata' => JSON.parse(result.first['[json]']) }
                end
            end

            def get_r10k_environments
                statement = @session.prepare('SELECT JSON * FROM environments')
                results   = @session.execute(statement)
                # Transform JSON formatted result into a Ruby hash
                environments = results.map do |result|
                    data = JSON.parse(result['[json]'])
                    data['modules'] = if data['modules']
                                        data['modules'].reduce({}) do |memo,(key,val)|
                                            memo.tap { |mem| mem[key] = JSON.parse(val) }
                                        end
                                      else
                                        {}
                                      end
                    [data.delete('name'), data]
                end.to_h
                # Transform data to R10k format
                environments.reduce({}) do |e_memo,(e_name,e_data)|
                    e_data['remote'] = e_data.delete('source')
                    e_data['ref']    = e_data.delete('version')
                    e_data['modules'] = e_data['modules'].reduce({}) do |m_memo,(m_name,m_data)|
                        m_data['git'] = m_data.delete('source')
                        m_data['ref']    = m_data.delete('version')
                        m_data.delete('type')
                        # If there's a source, save as hash. Otherwise, save as version (forge)
                        m_memo[m_name] = m_data['git'] ? m_data.compact : m_data['ref']
                        m_memo
                    end
                    e_memo[e_name] = e_data.compact
                    e_memo
                end
                environments
            end

            # TRUSTED EXTERNAL COMMAND METHODS

            def get_hiera_data(kwargs)
                uri = kwargs['uri']
                data = @session.execute(
                    'SELECT key,value FROM hieradata where level=%s' % "$$#{uri}$$",
                  ).rows.map { |row|
                    { row['key'] => row['value'] }
                  }.reduce({}, :merge)  
                data
            end
        end
    end
end