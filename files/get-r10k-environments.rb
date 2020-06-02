#!/opt/puppetlabs/puppet/bin/ruby

require 'puppet_data_service'
require 'json'
require 'yaml'

if $PROGRAM_NAME == __FILE__
  begin
    config = YAML.load_file('/etc/puppetlabs/puppet/puppet-data-service.yaml')

    client = PuppetDataService.connect(Facter.value['pds_database'], hosts: config['hosts'])
    data = client.execute('get', 'r10k_environments')

    puts data.to_json
  rescue StandardError, Exception => e
    # So PE doesn't blow itself up when this function fails,
    # we return any errors / exceptions as trusted external data
    data = {
      'trusted_external_error' => e.message,
      'error_backtrace' => e.backtrace
    }
    puts data.to_json
  end
end
