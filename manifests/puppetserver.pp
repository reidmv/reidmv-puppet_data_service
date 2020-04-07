class puppet_data_service::puppetserver {

  ['puppet_gem', 'puppetserver_gem'].each |$provider| {
    package { "${provider} cassandra-driver":
      name     => 'cassandra-driver',
      ensure   => present,
      provider => $provider,
    }
  }

  file { '/etc/puppetlabs/puppet/get-nodedata.rb':
    ensure => file,
    owner  => 'pe-puppet',
    group  => 'pe-puppet',
    mode   => '0755',
    source => 'puppet:///modules/puppet_data_service/get-nodedata.rb',
  }

  $hosts = puppetdb_query(@(PQL)).map |$rsrc| { $rsrc['certname'] }.sort
    resources[certname] {
      type = "Class" and
      title = "Puppet_data_service::Cassandra" }
    | PQL

  file { '/etc/puppetlabs/puppet/puppet-data-service.yaml':
    ensure  => file,
    owner   => 'pe-puppet',
    group   => 'pe-puppet',
    mode    => '0640',
    content => epp('puppet_data_service/puppet-data-service.yaml.epp', {
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
