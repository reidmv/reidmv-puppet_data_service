class puppet_data_service::cassandra (
  String $seeds          = getvar('facts.ipaddress'),
  String $listen_address = getvar('facts.ipaddress'),
  String $dc             = 'DC1',
  String $storage_port   = '7000',
) {

  # BUG https://issues.apache.org/jira/browse/CASSANDRA-15273
  # Remove as soon as Cassandra 3.11.7 or newer is released
  package { 'patch':
    ensure => present,
    before => Exec['patch cassandra startup file'],
  }
  exec { 'patch cassandra startup file':
    unless  => '/bin/grep -q runuser /etc/rc.d/init.d/cassandra',
    require => Package['cassandra'],
    notify  => Service['cassandra'],
    command => @(PATCH),
      /bin/patch /etc/rc.d/init.d/cassandra <<'EOF'
      diff --git a/redhat/cassandra b/redhat/cassandra
      index 677ff8c7ff..97a0447435 100644
      --- a/redhat/cassandra
      +++ b/redhat/cassandra
      @@ -69,15 +69,16 @@ case "$1" in
               echo -n "Starting Cassandra: "
               [ -d `dirname "$pid_file"` ] || \
                   install -m 755 -o $CASSANDRA_OWNR -g $CASSANDRA_OWNR -d `dirname $pid_file`
      -        su $CASSANDRA_OWNR -c "$CASSANDRA_PROG -p $pid_file" > $log_file 2>&1
      +        runuser -u $CASSANDRA_OWNR -- $CASSANDRA_PROG -p $pid_file > $log_file 2>&1
               retval=$?
      +        chown root.root $pid_file
               [ $retval -eq 0 ] && touch $lock_file
               echo "OK"
               ;;
           stop)
               # Cassandra shutdown
               echo -n "Shutdown Cassandra: "
      -        su $CASSANDRA_OWNR -c "kill `cat $pid_file`"
      +        runuser -u $CASSANDRA_OWNR -- kill `cat $pid_file`
               retval=$?
               [ $retval -eq 0 ] && rm -f $lock_file
               for t in `seq 40`; do
      --
      2.25.0
      EOF
      chmod a+x /etc/rc.d/init.d/cassandra
      /bin/systemctl daemon-reload
      | PATCH
  }

  class { 'cassandra::apache_repo':
    release => '311x',
    before  => Class['cassandra'],
  }

  class { 'cassandra':
    package_name   => 'cassandra',
    service_ensure => 'running',
    dc             => $dc,
    settings       => {
      'cluster_name'                => 'PuppetDataCluster',
      'endpoint_snitch'             => 'GossipingPropertyFileSnitch',
      'commitlog_directory'         => '/var/lib/cassandra/commitlog',
      'hints_directory'             => '/var/lib/cassandra/hints',
      'saved_caches_directory'      => '/var/lib/cassandra/saved_caches',
      'storage_port'                => $storage_port,
      'commitlog_sync'              => 'periodic',
      'commitlog_sync_period_in_ms' => '10000',
      'num_tokens'                  => 256,
      'partitioner'                 => 'org.apache.cassandra.dht.Murmur3Partitioner',
      'start_native_transport'      => true,
      'listen_address'              => $listen_address,
      'data_file_directories'       => [
        '/var/lib/cassandra/data'
      ],
      'seed_provider'               => [{
        'class_name' => 'org.apache.cassandra.locator.SimpleSeedProvider',
        'parameters' => [{
          'seeds' => $seeds,
        }]
      }],
    },
  }
  class { 'cassandra::schema':
    cqlsh_password => 'cassandra',
    cqlsh_user     => 'cassandra',
    cqlsh_host     => $::ipaddress,
    keyspaces      => {
      'puppet' => {
        durable_writes  => false,
        replication_map => {
          keyspace_class     => 'SimpleStrategy',
          replication_factor => 1,
        },
      },
    },
    tables         => {
      'environments' => {
        keyspace => 'puppet',
        columns  => {
          'name'        => 'text',
          'type'        => 'text',
          'remote'      => 'text',
          'modules'     => 'map<text,text>',
          'PRIMARY KEY' => '(name)'
        },
      },
      'nodedata'     => {
        keyspace => 'puppet',
        columns  => {
          certname      => 'text',
          environment   => 'text',
          release       => 'text',
          classes       => 'set<text>',
          'PRIMARY KEY' => '(certname)'
        },
      },
      'hieradata'    => {
        keyspace => 'puppet',
        columns  => {
          level         => 'text',
          key           => 'text',
          value         => 'text',
          'PRIMARY KEY' => '(level, key)'
        },
      }
    }
  }
}
