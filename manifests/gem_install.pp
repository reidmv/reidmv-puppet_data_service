# Builds and installs the puppet_data_service gem locally
class puppet_data_service::gem_install (
  Boolean $puppet_master = false,
  String $gemver = '0.1.0',
  String $gemdir = '/etc/puppetlabs/puppet/puppet_data_service',
  String $agentgem = '/opt/puppetlabs/puppet/bin/gem',
  String $puppetserver = '/opt/puppetlabs/bin/puppetserver'
) {
  package { 'git':
    ensure => installed,
  }

  $gem_build_dependencies = (
    package { ['make', 'automake', 'gcc', 'gcc-c++', 'kernel-devel']:
      ensure => present,
    }
  )

  file { $gemdir:
    ensure  => directory,
    mode    => '0755',
    recurse => true,
    purge   => true,
    source  => 'puppet:///modules/puppet_data_service/puppet_data_service',
    require => [Package['git'], $gem_build_dependencies],
  }
  exec { 'build_gem':
    path      => '/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin',
    command   => "cd ${gemdir} && ${agentgem} build ${gemdir}/puppet_data_service.gemspec",
    unless    => "[ -f ${gemdir}/puppet_data_service-${gemver}.gem ]",
    subscribe => File[$gemdir],
  }
  package { 'puppet_gem puppet_data_service':
    ensure   => $gemver,
    name     => 'puppet_data_service',
    provider => 'puppet_gem',
    source   => "${gemdir}/puppet_data_service-${gemver}.gem",
    require  => Exec['build_gem'],
  }
  if $puppet_master {
    package { 'puppetserver_gem puppet_data_service':
      ensure   => $gemver,
      name     => 'puppet_data_service',
      provider => 'puppetserver_gem',
      source   => "${gemdir}/puppet_data_service-${gemver}.gem",
      require  => Exec['build_gem'],
    }
  }
}
