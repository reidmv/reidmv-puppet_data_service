class puppet_data_service::puppetserver {

  $hosts = puppetdb_query(@(PQL)).map |$fact| { $fact['value'] }.sort
    facts[value] {
      name = 'ipaddress' and resources {
        type = 'Class' and title = 'Puppet_data_service::Cassandra'
      } 
    }
    | PQL

  $gem_build_dependencies = (
    package { ['make', 'automake', 'gcc', 'gcc-c++', 'kernel-devel']:
      ensure => present,
    }
  )

  $resource_dependencies = flatten([
    ['puppet_gem', 'puppetserver_gem'].map |$provider| {
      package { "${provider} cassandra-driver":
        ensure   => present,
        name     => 'cassandra-driver',
        provider => $provider,
        require  => $gem_build_dependencies,
      }
    },

    ['get-nodedata.rb', 'get-r10k-environments.rb'].map |$script| {
      file { "/etc/puppetlabs/puppet/${script}":
        ensure => file,
        owner  => 'pe-puppet',
        group  => 'pe-puppet',
        mode   => '0755',
        source => "puppet:///modules/puppet_data_service/${script}",
      }
    },

    file { '/etc/puppetlabs/puppet/puppet-data-service.yaml':
      ensure  => file,
      owner   => 'pe-puppet',
      group   => 'pe-puppet',
      mode    => '0640',
      content => epp('puppet_data_service/puppet-data-service.yaml.epp', {
        hosts => $hosts
      }),
    },
  ])

  pe_ini_setting { 'puppetserver puppetconf trusted external script':
    ensure  => present,
    path    => '/etc/puppetlabs/puppet/puppet.conf',
    setting => 'trusted_external_command',
    value   => '/etc/puppetlabs/puppet/get-nodedata.rb',
    section => 'master',
    require => $resource_dependencies,
    notify  => Service['pe-puppetserver'],
  }
}
