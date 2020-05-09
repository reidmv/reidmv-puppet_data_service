class puppet_data_service::puppetserver (
  String $database,
) {
  file { '/opt/puppetlabs/facter/facts.d':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }
  file { '/opt/puppetlabs/facter/facts.d/pds_database.yaml':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content => epp('puppet_data_service/pds_database.yaml.epp', {
      database => $database,
    })
  }
  class { 'puppet_data_service::gem_install':
    puppet_master => true,
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
