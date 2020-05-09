require 'puppet_data_service/contexts'
require 'puppet_data_service/loader'
module PuppetDataService
    def self.database_context_factory(database:, hosts:, opts: nil)
        require PuppetDataService.get_database_file(database)
        klass = "Pds#{database.capitalize()}"
        db_obj = eval("PuppetDataService::Databases::#{klass}").new(hosts: hosts)
        context = PuppetDataService::Contexts::DatabaseContext.new(db_obj)
        return context
    end
end
