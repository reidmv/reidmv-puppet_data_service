# /etc/puppetlabs/code/environments/production/modules/mymodule/lib/puppet/functions/mymodule/upcase.rb
require 'json'
require 'yaml'

begin
  require 'cassandra'
rescue LoadError
  raise Puppet::DataBinding::LookupError, '[puppet_data_service::data_hash] Must install cassandra-driver gem to use this backend'
end

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
    hosts = options.key?('hosts') ? Array(options['hosts']) : Array(Socket.gethostname)
    
    adapter = sessionadapter.adapt(closure_scope.environment)

    if adapter.session.nil?
      context.explain { '[puppet_data_service::data_hash] Database connection not cached...establishing...' }
      begin
        context.explain { "[puppet_data_service::data_hash] Database connection established to #{hosts.join(', ')}" }
        adapter.session = Cassandra.cluster(hosts: hosts).connect('puppet')
      rescue Cassandra::Error
        adapter.session = nil
        context.explain { '[puppet_data_service::data_hash] Failed to establish database connection' }
        return {}
      end
    else
      context.explain { '[puppet_data_service::data_hash] Re-using established database connection from cache' }
    end

    session = adapter.session

    data = session.execute(
      'SELECT key,value FROM hieradata where level=%s' % "$$#{uri}$$",
    ).rows.map { |row|
      { row['key'] => JSON.parse(row['value']) }
    }.reduce({}, :merge)

    data
  end
end
