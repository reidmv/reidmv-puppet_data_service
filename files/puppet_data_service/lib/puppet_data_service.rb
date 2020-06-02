require "puppet_data_service/factory"
require "puppet_data_service/version"
module PuppetDataService
  SUPPORTED_DATABASES = ['cassandra', 'mongodb'].freeze

  ALL_OP_VERBS = ['list', 'get', 'add', 'modify', 'remove'].freeze

  ALL_OP_TARGETS = ['hiera',
                    'module',
                    'node',
                    'puppet_environment',
                    'nodedata',
                    'r10k_environments',
                    'hiera_data'].freeze

  ALL_OP_SYMBOLS = [:list_hiera,
                    :get_hiera,
                    :add_hiera,
                    :remove_hiera,
                    :list_module,
                    :add_module,
                    :modify_module,
                    :remove_module,
                    :list_node,
                    :get_node,
                    :add_node,
                    :modify_node,
                    :remove_node,
                    :list_puppet_environment,
                    :modify_puppet_environment,
                    :remove_puppet_environment,
                    :get_nodedata,
                    :get_r10k_environments,
                    :get_hiera_data].freeze
  
  PDS_DATABASES_DIR = 'puppet_data_service/databases'

  # Creates and returns a database context object.
  #
  # @param [String] database
  # @param [Array] hosts
  # @param [Hash] db_config
  def self.connect(database:, hosts:, db_config: {}, **kwargs)
      PuppetDataService.database_context_factory(database: database, hosts: hosts, db_config: db_config, opts: kwargs)
  end

end
