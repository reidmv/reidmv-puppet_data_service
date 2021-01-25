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
    env_results = @session.execute('SELECT JSON * FROM environments')
    mod_results = @session.execute('SELECT JSON * FROM modules')

    # Transform JSON formatted array of module results into a nested Ruby hash
    modules = mod_results.map { |res| JSON.parse(res['[json]']) }
                         .group_by { |res| res['environment'] }
                         .reduce({}) do |e_memo,(env,mods)|
                           mod_hash = mods.reduce({}) do |m_memo,m_data|
                             m_data.delete('environment')
                             m_memo[m_data.delete('name')] = m_data
                             m_memo
                           end
                           e_memo[env] ||= {}
                           e_memo[env] = e_memo[env].merge(mod_hash)
                           e_memo
                         end

    # Transform JSON formatted environment results into a Ruby hash with
    # attached modules
    environments = env_results.map { |res| JSON.parse(res['[json]']) }
                              .reduce({}) do |memo,data|
                                name = data.delete('name')
                                data['modules'] = modules[name] || {}
                                memo[name] = data
                                memo
                              end

    # Transform beautiful data to ugly R10k format
    environments.reduce({}) do |e_memo,(e_name,e_data)|
      e_data['remote'] = e_data.delete('source')
      e_data['ref']    = e_data.delete('version')

      e_data['modules'] = e_data['modules'].reduce({}) do |m_memo,(m_name,m_data)|
        m_data['git'] = m_data.delete('source')
        m_data['ref']    = m_data.delete('version')

        type = m_data.delete('type')

        # If it's a git module, save as hash. Otherwise, save as version (forge)
        m_memo[m_name] = (type == 'git') ? m_data.compact : m_data['ref']
        m_memo
      end

      e_memo[e_name] = e_data.compact
      e_memo
    end

    environments
  end
end

if $PROGRAM_NAME == __FILE__
  config = YAML.load_file('/etc/puppetlabs/puppet/pds.yaml')

  client = PuppetDataClient.new(hosts: config['hosts'])
  data = client.get_r10k_environments

  puts data.to_json
end
