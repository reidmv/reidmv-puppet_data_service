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
    statement = @session.prepare('SELECT * FROM nodedata WHERE certname=?').bind([certname])
    result    = @session.execute(statement)

    data = result.first

    # Convert the Ruby Set object into an array
    data['classes'] = data.delete('classes').to_a unless data['classes'].nil?

    {'nodedata' => data }
  end
end

if __FILE__ == $0
  config = YAML.load_file('/etc/puppetlabs/puppet/puppet-metadata-service.yaml')

  PuppetMetadataClient.new(hosts: config['hosts'])
  data = PuppetMetadataClient.get_nodedata(certname: ARGV[0])

  puts data.to_json
end
