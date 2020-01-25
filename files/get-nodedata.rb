#!/opt/puppetlabs/puppet/bin/ruby

require 'cassandra'
require 'json'
require 'yaml'

class PuppetMetadataClient
  def initialize(hosts:)
    @cluster = Cassandra.cluster(hosts: hosts)
    keyspace = 'puppet'

    @session  = @cluster.connect(keyspace) # create session, optionally scoped to a keyspace, to execute queries
  end

  def get_nodedata(certname:)
    statement = @session.prepare('SELECT json classes,environment,release FROM nodedata WHERE certname=?').bind([certname])
    result    = @session.execute(statement)

    if result.first.nil?
      return {}
    else
      return {'nodedata' => JSON.parse(result.first['[json]']) }
    end
  end
end

if __FILE__ == $0
  config = YAML.load_file('/etc/puppetlabs/puppet/puppet-metadata-service.yaml')

  client = PuppetMetadataClient.new(hosts: config['hosts'])
  data = client.get_nodedata(certname: ARGV[0])

  puts data.to_json
end