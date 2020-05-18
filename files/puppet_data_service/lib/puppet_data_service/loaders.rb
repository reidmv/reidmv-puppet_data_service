module PuppetDataService

    # The Loaders module contains functions that load things from disk.
    module Loaders
        # Reads a PDS config from disk
        #
        # @param [String] conf_path
        def self.get_config(conf_path)
            require 'yaml'
            conf = YAML.load_file(conf_path)
            conf
        end

        # Reads the pds_database fact value from disk
        def self.get_database_fact
            require 'yaml'
            database = YAML.load_file('/etc/puppetlabs/facter/facts.d/pds_database.yaml')
            database['database']
        end

        # Returns the path to a PdsDatabase file
        def self.get_database_file(database)
            $LOAD_PATH.unshift(PDS_DATABASES_DIR)
            dbfile = File.join(PDS_DATABASES_DIR, "pds_#{database}.rb")
            dbfile
        end
    end
end