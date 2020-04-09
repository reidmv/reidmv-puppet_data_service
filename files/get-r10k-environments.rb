#!/opt/puppetlabs/puppet/bin/ruby

require 'cassandra'
require 'json'
require 'yaml'

class PuppetDataClient
  def initialize(hosts:)
    @cluster = Cassandra.cluster(hosts: hosts)
    keyspace = 'puppet'

    @session  = @cluster.connect(keyspace) # create session, optionally scoped to a keyspace, to execute queries
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
end

if $PROGRAM_NAME == __FILE__
  config = YAML.load_file('/etc/puppetlabs/puppet/puppet-data-service.yaml')

  client = PuppetDataClient.new(hosts: config['hosts'])
  data = client.get_r10k_environments

  puts data.to_json
end
