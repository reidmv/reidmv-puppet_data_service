# Installs the custom external fact pds_database
class puppet_data_service::pds_fact (
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
}
