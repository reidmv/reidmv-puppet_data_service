#!/usr/bin/env ruby
#
# This script reads all the Hiera data present in a Hiera data directory, and
# outputs a cqlsh shell script which imports all the levels, keys, and values
# into Cassandra for the Puppet Data Service reference implementation.
#
# Run this script from a Hiera datadir, such as <control-repo>/data.
#
# Save the ouptut to a file, and modify or run that file on one of the
# Cassandra nodes.
require 'yaml'
require 'json'

puts '#!/bin/bash'
puts "cqlsh $(hostname -f) <<'EOF'"

Dir.glob('**/*.yaml').each do |fn|
  begin
    data = YAML.load_file(fn)
    unless data.is_a?(Hash)
      STDERR.puts "Failed to load #{fn}; data is not a hash"
      next
    end
    data.each do |k,v|
      puts "INSERT INTO puppet.hieradata (level, key, value) VALUES ('#{fn.delete_suffix('.yaml')}', '#{k}', $$#{v.to_json}$$);"
    end
  end
end

puts 'EOF'
