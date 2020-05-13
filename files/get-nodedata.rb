#!/opt/puppetlabs/puppet/bin/ruby

require 'puppet_data_service'
require 'json'
require 'yaml'

if $PROGRAM_NAME == __FILE__
  config = YAML.load_file('/etc/puppetlabs/puppet/puppet-data-service.yaml')

  client = PuppetDataService.connect(Facter.value['pds_database'], hosts: config['hosts'])
  data = client.execute('get', 'nodedata', certname: ARGV[0])

  puts data.to_json
end
