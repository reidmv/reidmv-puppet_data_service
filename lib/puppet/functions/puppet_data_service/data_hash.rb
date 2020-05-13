# /etc/puppetlabs/code/environments/production/modules/mymodule/lib/puppet/functions/mymodule/upcase.rb
require 'json'
require 'yaml'
require 'puppet_data_service'

Puppet::Functions.create_function(:'puppet_data_service::data_hash') do
  dispatch :hiera_data do
    param 'Hash', :options
    param 'Puppet::LookupContext', :context
  end

  def sessionadapter
    @sessionadapter ||= Class.new(Puppet::Pops::Adaptable::Adapter) do
      attr_accessor :session
      def self.name
        'Puppet_data_service::Data_hash::SessionAdapter'
      end
    end
    @sessionadapter
  end

  def hiera_data(options, context)
    uri = options['uri']
    hosts = hosts.nil? ? Array(Socket.gethostname) : Array(options['hosts'])

    adapter = sessionadapter.adapt(closure_scope.environment)

    if adapter.session.nil?
      context.explain { '[puppet_data_service::data_hash] Database connection not cached...establishing...' }
      begin
        context.explain { "[puppet_data_service::data_hash] Database connection established to #{hosts.join(', ')}" }
        adapter.session = PuppetDataService.connect(database: Facter.value['pds_database'],
                                                    hosts: hosts)
      rescue PuppetDataService::Error => e
        adapter.session = nil
        context.explain { '[puppet_data_service::data_hash] Failed to establish database connection' }
        context.explain { "[puppet_data_service::data_hash][PuppetDataService::Error] #{e.message}"}
        return {}
      end
    else
      context.explain { '[puppet_data_service::data_hash] Re-using established database connection from cache' }
    end

    session = adapter.session

<<<<<<< HEAD
    data = session.execute('get', 'hiera_data', uri: uri)
    
=======
    data = session.execute(
      'SELECT key,value FROM hieradata where level=%s' % "$$#{uri}$$",
    ).rows.map { |row|
      { row['key'] => JSON.parse(row['value']) }
    }.reduce({}, :merge)

>>>>>>> c24893c0fe2379b1f62163dd48f40a8d9616e17b
    data
  end
end
