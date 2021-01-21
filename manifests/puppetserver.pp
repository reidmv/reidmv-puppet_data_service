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

  # Collect the following set of resource declarations in an array, so that
  # they can be used as a dependency target
  $resource_dependencies = flatten([
    ['puppet_gem', 'puppetserver_gem'].map |$provider| {
      package { "${provider} cassandra-driver":
        ensure   => present,
        name     => 'cassandra-driver',
        provider => $provider,
        require  => $gem_build_dependencies,
      }
    },

    # Note: managing this directory may conflict with other modules which
    # install a trusted-external-commands script. If a conflict is encountered,
    # management of this directory may need to be centralized in another
    # module, such as in the puppet_enterprise module.
    file { "/etc/puppetlabs/puppet/trusted-external-commands":
      ensure => directory,
      owner  => 'pe-puppet',
      group  => 'pe-puppet',
      mode   => '0755',
    },

    file { "/etc/puppetlabs/puppet/trusted-external-commands/pds.rb":
      ensure => file,
      owner  => 'pe-puppet',
      group  => 'pe-puppet',
      mode   => '0755',
      source => "puppet:///modules/puppet_data_service/pds.rb",
    },

    file { "/etc/puppetlabs/puppet/get-r10k-environments.rb":
      ensure => file,
      owner  => 'pe-puppet',
      group  => 'pe-puppet',
      mode   => '0755',
      source => "puppet:///modules/puppet_data_service/get-r10k-environments.rb",
    },

    file { '/etc/puppetlabs/puppet/pds.yaml':
      ensure  => file,
      owner   => 'pe-puppet',
      group   => 'pe-puppet',
      mode    => '0640',
      content => epp('puppet_data_service/pds.yaml.epp', {
        hosts => $hosts
      }),
    },
  ])

  pe_ini_setting { 'puppetserver puppetconf trusted external script':
    ensure  => present,
    path    => '/etc/puppetlabs/puppet/puppet.conf',
    setting => 'trusted_external_command',
    value   => '/etc/puppetlabs/puppet/trusted-external-commands',
    section => 'master',
    require => $resource_dependencies,
    notify  => Service['pe-puppetserver'],
  }
}
