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

  def get_nodedata(certname:)
    statement = @session.prepare('SELECT puppet_environment,puppet_classes,userdata FROM nodedata WHERE name = ?').bind([certname])
    result    = @session.execute(statement)
    data      = result.first

    return {} if data.nil?

    data['puppet_classes'] = data['puppet_classes'].to_a unless data['puppet_classes'].nil?
    data['userdata'] = JSON.parse(data['userdata']) unless data['userdata'].nil?

    data
  end
end

if $PROGRAM_NAME == __FILE__
  config = YAML.load_file('/etc/puppetlabs/puppet/pds.yaml')

  client = PuppetDataClient.new(hosts: config['hosts'])
  data = client.get_nodedata(certname: ARGV[0])

  puts data.to_json
end
