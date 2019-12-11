#!/bin/bash

cqlsh $(hostname -f) <<EOF
  INSERT INTO puppet.nodedata (certname, environment, release) 
  VALUES ('testnode1.example.com', 'production', 'r42');

  INSERT INTO puppet.hieradata (level, key, value)
  VALUES ('nodes/testnode1.example.com', 'class::value1', 'nodes');

  INSERT INTO puppet.hieradata (level, key, value)
  VALUES ('environments/production', 'class::value1', 'environments-prod');

  INSERT INTO puppet.hieradata (level, key, value)
  VALUES ('environments/production', 'class::value2', 'environments-prod');

  INSERT INTO puppet.hieradata (level, key, value)
  VALUES ('environments/production', 'class::value3', 'environments-prod');

  INSERT INTO puppet.hieradata (level, key, value)
  VALUES ('environments/development', 'class::value1', 'environments-dev');
EOF
