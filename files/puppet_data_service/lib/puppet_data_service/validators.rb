require 'puppet_data_service/errors'

module PuppetDataService
    module Validators
        module Databases
            # Checks if a database is supported
            #
            # @param [String] database
            def self.is_valid?(database)
                input_type = 'database'
                if !SUPPORTED_DATABASES.include?(database)
                    raise Errors::ValidationError.new(
                        "Puppet Data Service does not support #{database} database!",
                        input: database,
                        input_type: input_type
                    )
                end
                true
            end
        end

        module OpVerbs
            # Checks if an op verb is valid.
            # If param strict is true will raise an error
            #
            # @param [String] op
            # @param [Bool] strict
            def self.is_valid?(op, strict: true)
                input_type = 'op_verb'
                if !ALL_OP_VERBS.include?(op)
                    if strict
                        raise Errors::ValidationError.new(
                            "Op verb #{op} is invalid! Valid op verbs are #{ALL_OP_VERBS}",
                            input: op,
                            input_type: input_type
                        )
                    end
                    return false
                end
                true
            end
        end

        module OpTargets
            # Check is an op target is valid.
            # If param strict is true will raise an error
            #
            # @param [String] target
            # @param [Bool] strict
            def self.is_valid?(target, strict: true)
                input_type = 'op_target'
                if !ALL_OP_TARGETS.include?(target)
                    if strict
                        raise Errors::ValidationError.new(
                            "Op verb #{target} is invalid! Valid op verbs are #{ALL_OP_TARGETS}",
                            input: target,
                            input_type: input_type
                        )
                    end
                    return false
                end
                true
            end
        end
    end
end