lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'puppet_data_service/version'

Gem::Specification.new do |spec|
  spec.name          = 'puppet_data_service'
  spec.version       = PuppetDataService::VERSION
  spec.authors       = ['Heston Snodgrass']
  spec.email         = ['heston.snodgrass@puppet.com']

  spec.summary       = 'Supporting gem for the Puppet Data Service'
  spec.homepage      = 'https://github.com/reidmv/reidmv-puppet_data_service'
  spec.license       = 'Apache 2.0'

#  spec.metadata['allowed_push_host'] = 'TODO: Set to http://mygemserver.com'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/reidmv/reidmv-puppet_data_service'
  spec.metadata['changelog_uri'] = 'https://github.com/reidmv/reidmv-puppet_data_service'

  # Specify which files should be added to the gem when it is released.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    Dir['**/*'].reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.9'
  spec.add_runtime_dependency 'cassandra-driver', '~> 3.2'
  spec.add_runtime_dependency 'mongo', '~> 2.12'
  spec.add_runtime_dependency 'hocon', '~> 1.3'
end
