# /etc/puppetlabs/code/environments/production/modules/mymodule/lib/puppet/functions/mymodule/upcase.rb
require 'json'
require 'yaml'

begin
  require 'cassandra'
rescue LoadError => e
  raise Puppet::DataBinding::LookupError, "[puppet_metadata_service::data_hash] Must install cassandra-driver gem to use this backend"
end

Puppet::Functions.create_function(:'puppet_metadata_service::data_hash') do

  dispatch :hiera_data do
    param 'Hash', :options
    param 'Puppet::LookupContext', :context
  end

  def sessionadapter
    @sessionadapter ||= Class.new(Puppet::Pops::Adaptable::Adapter) do
      attr_accessor :session
      def self.name()
        "Puppet_metadata_service::Data_hash::SessionAdapter"
      end
    end
    @sessionadapter
  end

  def hiera_data(options, context)
    uri = options['uri']
    hosts = hosts.nil? ? Array(Socket.gethostname) : Array(options['hosts'])

    adapter = sessionadapter.adapt(closure_scope().environment)

    if adapter.session.nil?
      context.explain { '[puppet_metadata_service::data_hash] Database connection not cached...establishing...' }
      begin
        context.explain { "[puppet_metadata_service::data_hash] Database connection established to #{hosts.join(', ')}" }
        adapter.session = Cassandra.cluster(hosts: hosts).connect('puppet')
      rescue Cassandra::Error => e
        adapter.session = nil
        context.explain { '[puppet_metadata_service::data_hash] Failed to establish database connection' }
        return {}
      end
    else
      context.explain { '[puppet_metadata_service::data_hash] Re-using established database connection from cache' }
    end

    session = adapter.session

    data = session.execute(
      "SELECT key,value FROM hieradata where level=%s" % "$$#{uri}$$").rows.map { |row|
        { row['key'] => row['value'] }
      }.reduce({}, :merge
    )

    return data
  end
end