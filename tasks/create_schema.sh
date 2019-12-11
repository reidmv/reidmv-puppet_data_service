#!/bin/bash

cqlsh $(hostname -f) <<EOF
  CREATE KEYSPACE IF NOT EXISTS puppet WITH REPLICATION = { 'class' : 'NetworkTopologyStrategy', 'A' : 1, 'B' : 1 };

  CREATE TABLE IF NOT EXISTS puppet.nodedata (
     certname text PRIMARY KEY,
     environment text,
     release text );

  CREATE TABLE IF NOT EXISTS puppet.hieradata (
     level text,
     key text,
     value text,
     PRIMARY KEY (level, key) );
EOF
