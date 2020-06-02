module PuppetDataService
    module Databases
        # The abstract class for creating database objects.
        # This class is the interface used by the DatabaseContext
        # to call our strategies (concrete database objects).
        class PdsDatabase

            @@plugin_type = :pds_database

            # @abstract
            def initialize(_hosts:, _db_config:, _keyspace:, **_kwargs)
                raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}"
            end

            # @abstract
            def list_hiera(_kwargs)
                raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}"
            end

            # @abstract
            def get_hiera(_kwargs)
                raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}"
            end

            # @abstract
            def add_hiera(_kwargs)
                raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}"
            end

            # @abstract
            def remove_hiera(_kwargs)
                raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}"
            end

            # @abstract
            def list_module(_kwargs)
                raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}"
            end

            # @abstract
            def add_module(_kwargs)
                raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}"
            end

            # @abstract
            def modify_module(_kwargs)
                raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}"
            end

            # @abstract
            def remove_module(_kwargs)
                raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}"
            end

            # @abstract
            def list_node(_kwargs)
                raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}"
            end

            # @abstract
            def get_node(_kwargs)
                raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}"
            end

            # @abstract
            def add_node(_kwargs)
                raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}"
            end

            # @abstract
            def modify_node(_kwargs)
                raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}"
            end

            # @abstract
            def remove_node(_kwargs)
                raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}"
            end

            # @abstract
            def list_puppet_environment(_kwargs)
                raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}"
            end

            # @abstract
            def add_puppet_environment(_kwargs)
                raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}"
            end

            # @abstract
            def modify_puppet_environment(_kwargs)
                raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}"
            end

            # @abstract
            def remove_puppet_environment(_kwargs)
                raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}"
            end

            # @abstract
            # @param [String] certname
            def get_nodedata(_certname:)
                raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}"
            end

            # @abstract
            def get_r10k_environments
                raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}"
            end

            # @abstract
            def get_hiera_data(_kwargs)
                raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}"
            end
        end
    end
end