class puppet_data_service::puppetserver (
  String $database,
) {
  class { 'puppet_data_service::pds_fact':
    database => $database,
  }
  -> class { 'puppet_data_service::gem_install':
    puppet_master => true,
  }
  ['get-nodedata.rb', 'get-r10k-environments.rb'].map |$script| {
    file { "/etc/puppetlabs/puppet/${script}":
      ensure => file,
      owner  => 'pe-puppet',
      group  => 'pe-puppet',
      mode   => '0755',
      source => "puppet:///modules/puppet_data_service/${script}",
    }
  }
  case downcase($database) {
    'cassandra': {
      include 'puppet_data_service::puppetserver::cassandra'
    }
    default: {
      alert("Database ${database} is not supported by the Puppet metadata service!")
    }
  }
}
