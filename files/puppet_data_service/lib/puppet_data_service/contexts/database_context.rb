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
            def initialize(database)
                @database = database
            end

            # Allow replacing the database in the context at runtime
            def database=(database)
                @database = database
            end

            def execute(op, target, **kwargs)
                @database.send("#{op}_#{target}".to_sym, kwargs)
            end
        end
    end
end