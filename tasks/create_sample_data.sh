#!/bin/bash

cqlsh $(hostname -f) <<EOF
  INSERT INTO puppet.nodedata (certname, environment, release)
  VALUES ('testnode1.example.com', 'production', 'r42');

  INSERT INTO puppet.hieradata (level, key, value)
  VALUES ('nodes/testnode1.example.com', 'sample::value1', 'nodes');

  INSERT INTO puppet.hieradata (level, key, value)
  VALUES ('environments/production', 'sample::value1', 'environments-prod');

  INSERT INTO puppet.hieradata (level, key, value)
  VALUES ('environments/production', 'sample::value2', 'environments-prod');

  INSERT INTO puppet.hieradata (level, key, value)
  VALUES ('environments/production', 'sample::value3', 'environments-prod');

  INSERT INTO puppet.hieradata (level, key, value)
  VALUES ('environments/development', 'sample::value1', 'environments-dev');
EOF
