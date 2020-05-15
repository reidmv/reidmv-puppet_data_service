# Builds and installs the puppet_data_service gem locally
class puppet_data_service::gem_install (
  Boolean $puppet_master = false,
  String $gemdir = '/etc/puppetlabs/puppet/puppet_data_service',
  String $agentgem = '/opt/puppetlabs/puppet/bin/gem',
  String $puppetserver = '/opt/puppetlabs/bin/puppetserver'
) {
  file { $gemdir:
    ensure  => directory,
    mode    => '0755',
    recurse => true,
    purge   => true,
    source  => 'puppet:///modules/puppet_data_service/puppet_data_service',
  }
  exec { 'build_gem':
    command     => "${agentgem} build -C ${gemdir}",
    refreshonly => true,
    subscribe   => File[$gemdir],
  }
  exec { 'install_to_agent_ruby':
    command     => "/bin/cd ${gemdir} && ${agentgem} install --local puppet_data_service",
    refreshonly => true,
    subscribe   => Exec['build_gem'],
  }
  if $puppet_master {
    exec { 'install_to_master_jruby':
      command     => "/bin/cd ${gemdir} && ${puppetserver} gem install --local puppet_data_service",
      refreshonly => true,
      subscribe   => Exec['build_gem'],
    }
  }
}
