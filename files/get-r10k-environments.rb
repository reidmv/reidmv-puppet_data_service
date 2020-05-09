#!/opt/puppetlabs/puppet/bin/ruby

require 'puppet_data_service'
require 'json'
require 'yaml'

if $PROGRAM_NAME == __FILE__
  config = YAML.load_file('/etc/puppetlabs/puppet/puppet-data-service.yaml')

  client = PuppetDataService.connect(hosts: config['hosts'])
  data = client.execute('get', 'r10k_environments')

  puts data.to_json
end
