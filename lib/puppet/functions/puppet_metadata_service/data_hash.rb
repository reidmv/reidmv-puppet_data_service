# /etc/puppetlabs/code/environments/production/modules/mymodule/lib/puppet/functions/mymodule/upcase.rb
require 'cassandra'
require 'json'
require 'yaml'

Puppet::Functions.create_function(:'puppet_metadata_service::data_hash') do

  dispatch :hiera_backend do
    param 'Hash', :options
    param 'Puppet::LookupContext', :context
  end

  def hiera_backend(options, context)
    session = context.cached_value(:session)

    if session.nil?
      session = new_session
      context.cache(:session, session)
    end
  end

  def new_session
    # TODO
  end

  def get_level_data(level, session)
    # TODO
  end

end
