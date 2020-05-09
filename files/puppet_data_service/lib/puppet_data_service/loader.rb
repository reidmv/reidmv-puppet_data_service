module PuppetDataService
    def self.get_config(conf_path)
        require 'yaml'
        return YAML.load_file(conf_path)
    end

    def self.get_database_fact
        require 'yaml'
        database = YAML.load_file('/etc/puppetlabs/facter/facts.d/pds_database.yaml')
        return database['database']
    end

    def self.get_database_file(database)
        $LOAD_PATH.unshift(PDS_DATABASES_DIR)
        return File.join(PDS_DATABASES_DIR, "pds_#{database}.rb")
    end
end