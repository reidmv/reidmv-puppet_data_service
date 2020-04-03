class puppet_metadata_service::cassandra (
  String $seeds,
  String $dc = 'DC1',
) {

  class { 'cassandra::apache_repo':
    release => '311x',
    before  => Class['cassandra'],
  }

  class { 'cassandra':
    package_name => 'cassandra',
    dc           => $dc,
    settings     => {
      'cluster_name' => 'PuppetMetadataCluster',
      'endpoint_snitch' => 'GossipingPropertyFileSnitch',
      'commitlog_directory' => '/var/lib/cassandra/commitlog',
      'hints_directory' => '/var/lib/cassandra/hints',
      'saved_caches_directory' => '/var/lib/cassandra/saved_caches',
      'commitlog_sync' => 'periodic',
      'commitlog_sync_period_in_ms' => '10000',
      'num_tokens' => 256,
      'partitioner' => 'org.apache.cassandra.dht.Murmur3Partitioner',
      'start_native_transport' => true,
      'data_file_directories' => [
        '/var/lib/cassandra/data'
      ],
      'seed_provider' => [{
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
      }
    },
    tables         => {
      'nodedata' => {
        columns  => {
          certname      => 'text',
          environment   => 'text',
          release       => 'text',
          classes       => 'set<text>',
          'PRIMARY KEY' => '(certname)'
        },
        keyspace => 'puppet'
      },
      'hieradata' => {
        columns  => {
          level         => 'text',
          key           => 'text',
          value         => 'text',
          'PRIMARY KEY' => '(level, key)'
        },
        keyspace => 'puppet'
      }
    }
  }
}
