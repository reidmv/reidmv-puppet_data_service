require 'puppet_data_service/validators'

module PuppetDataService
    module Contexts
        # The DatabaseContext class holds the behavioral context for all database operations.
        # By using the DatabaseContext class as the general adapter for database operations,
        # the rest of the code has a single interface regardless of what backend it's
        # using. This uses the strategy design pattern, where each concrete Database object
        # is considered a different strategy.
        class DatabaseContext
            attr_writer :database

            # Accept a database at context creation
            #
            # @param [PdsDatabase] database
            def initialize(database)
                @database = database
            end

            # Allow replacing the database in the context at runtime
            #
            # @param [PdsDatabase] database
            def database=(database)
                @database = database
            end

            # Execute a method on the current database.
            # All database object methods follow the same naming
            # convention: <op verb>_<op target>. Valid verbs and
            # targets are declared as constants in PuppetDataService.
            #
            # @param [String] op
            # @param [String] target
            def execute(op, target, **kwargs)
                Validators::OpVerbs.is_valid?(op)
                Validators::OpTargets.is_valid?(target)
                @database.send("#{op}_#{target}".to_sym, kwargs)
            end
        end
    end
end