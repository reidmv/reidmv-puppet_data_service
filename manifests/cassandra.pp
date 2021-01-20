class puppet_data_service::cassandra (
  String $seeds               = getvar('facts.ipaddress'),
  String $listen_address      = getvar('facts.ipaddress'),
  String $dc                  = 'DC1',
  String $storage_port        = '7000',
  String $max_heap_size_in_mb = '256',
) {
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
      'nodedata' => {
        keyspace => 'puppet',
        columns  => {
          name               => 'text',
          puppet_environment => 'text',
          puppet_classes     => 'set<text>',
          userdata           => 'text',
          'PRIMARY KEY'      => '(name)'
        },
      },
      'hieradata' => {
        keyspace => 'puppet',
        columns  => {
          level         => 'text',
          key           => 'text',
          value         => 'text',
          'PRIMARY KEY' => '(level, key)'
        },
      },
      'environments' => {
        keyspace => 'puppet',
        columns  => {
          'name'        => 'text',
          'type'        => 'text',
          'source'      => 'text',
          'version'     => 'text',
          'PRIMARY KEY' => '(name)'
        },
      },
      'modules' => {
        keyspace => 'puppet',
        columns  => {
          'environment' => 'text',
          'name'        => 'text',
          'type'        => 'text',
          'source'      => 'text',
          'version'     => 'text',
          'PRIMARY KEY' => '(environment, name)'
        },
      },
    }
  }

  cassandra::file { "Set Java/Cassandra max heap size to ${max_heap_size_in_mb}.":
    file       => 'cassandra-env.sh',
    file_lines => {
      'MAX_HEAP_SIZE' => {
        line  => "MAX_HEAP_SIZE='${max_heap_size_in_mb}M'",
        match => '^#?MAX_HEAP_SIZE=.*',
      },
    },
  }

  # for now, calculating a default heap_new_size to keep things simple
  $heap_new_size = $max_heap_size_in_mb / 4

  cassandra::file { "Set Java/Cassandra heap new size to ${heap_new_size}.":
    file       => 'cassandra-env.sh',
    file_lines => {
      'HEAP_NEWSIZE' => {
        line  => "HEAP_NEWSIZE='${heap_new_size}M'",
        match => '^#?HEAP_NEWSIZE=.*',
      },
    },
  }

}
