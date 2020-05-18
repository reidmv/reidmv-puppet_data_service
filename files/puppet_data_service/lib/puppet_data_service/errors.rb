module PuppetDataService
    
    # Included in all errors so that all errors can be caught with PuppetDataService::Error
    module Error
    end

    module Errors

        # Database connection error wrapper
        # As this is a wrapper error, we should always include
        # the original error with the param o_error.
        # This error is used as an interface for rescue blocks
        # so we can catch database connection errors without
        # knowing the specific database is in use.
        #
        # @param [String] msg
        # @param [StandardError] o_error
        # @param [String] dbtype
        # @param [Array] hosts
        class ConnError < StandardError
            include Error

            attr_reader :msg
            attr_reader :o_error
            attr_reader :dbtype
            attr_reader :hosts
            def initialize(msg, o_error, dbtype: nil, hosts: nil)
                @msg = msg
                @o_error = o_error
                @dbtype = dbtype
                @hosts = hosts
                super(@msg)
            end
        end

        # Validation error
        # This error should be raised when method / function input
        # fails a validation function.
        #
        # @param [String] msg
        # @param [String] input
        # @param [String] input_type
        class ValidationError < StandardError
            attr_reader :msg
            attr_reader :input
            attr_reader :input_type

            def initialize(msg, input: nil, input_type: nil)
                @msg = msg
                @input = input
                @input_type = input_type
                super(msg)
            end
        end
    end
end