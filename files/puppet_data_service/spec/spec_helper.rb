require "bundler/setup"
require "puppet_data_service"
require "cassandra"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.before(:each) do
    cas_cluster = double
    allow(cas_cluster).to receive(:connect).and_return(true)
    allow(Cassandra).to receive(:cluster).and_return(cas_cluster)
  end

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
