require 'puppet_data_service/contexts'
require 'puppet_data_service/loaders'
require 'puppet_data_service/validators'

module PuppetDataService

    # Creates a PdsDatabase object and a DatabaseContext object.
    # The PdsDatabase object will be assigned to the database
    # param of the DatabaseContext object. Returns the
    # DatabaseContext object. 
    #
    # @param [String] database
    # @param [Array] hosts
    # @param [Hash] opts
    def self.database_context_factory(database:, hosts:, opts: nil)
        Validators::Databases.is_valid?(database)
        require Loaders.get_database_file(database) # Require database file by file path
        klass = "Pds#{database.capitalize()}"
        db_obj = eval("PuppetDataService::Databases::#{klass}").new(hosts: hosts)
        context = Contexts::DatabaseContext.new(db_obj)
        return context
    end
end
