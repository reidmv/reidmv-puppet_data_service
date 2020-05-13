class puppet_data_service::puppetserver (
  String $database,
) {
  class { 'puppet_data_service::pds_fact':
    database => $database,
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
