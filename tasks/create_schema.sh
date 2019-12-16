#!/bin/bash

cqlsh $(hostname -f) <<EOF
  CREATE KEYSPACE IF NOT EXISTS puppet WITH REPLICATION = { 'class' : 'NetworkTopologyStrategy', 'DC1' : 2, 'DC2' : 2 };

  CREATE TABLE IF NOT EXISTS puppet.nodedata (
     certname text PRIMARY KEY,
     environment text,
     release text,
     classes set<text>
  );

  CREATE TABLE IF NOT EXISTS puppet.hieradata (
     level text,
     key text,
     value text,
     PRIMARY KEY (level, key)
  );
EOF
