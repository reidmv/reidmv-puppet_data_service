class puppet_metadata_service::puppetserver {

  file { '/etc/puppetlabs/puppet/get-nodedata.rb':
    ensure => file,
    owner  => 'pe-puppet',
    group  => 'pe-puppet',
    mode   => '0755',
    source => 'puppet:///modules/puppet_metadata_service/get-nodedata.rb',
  }

  $hosts = puppetdb_query('resources[certname] { type = "Class" and title = "Puppet_metadata_service::Cassandra" }').map |$resource| {
    $resource['certname']
  }.sort

  file { '/etc/puppetlabs/puppet/puppet-metadata-service.yaml':
    ensure  => file,
    owner   => 'pe-puppet',
    group   => 'pe-puppet',
    mode    => '0640',
    content => epp('puppet_metadata_service/puppet-metadata-service.yaml.epp', {
      hosts => $hosts
    }),
  }

  pe_ini_setting { 'puppetserver puppetconf trusted external script':
    ensure  => present,
    path    => '/etc/puppetlabs/puppet/puppet.conf',
    setting => 'trusted_external_command',
    value   => '/etc/puppetlabs/puppet/get-nodedata.rb',
    section => 'master',
  }
}
