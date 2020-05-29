# Puppet Data Service Pattern & Reference Implementation

#### Table of Contents

1. [Description](#description)
2. [Setup - Getting started with puppet\_data\_service](#setup)
3. [Usage - Configuration options and additional functionality](#usage)
4. [Limitations - OS compatibility, etc.](#limitations)
5. [Development - Guide for contributing to the module](#development)

## Description

The Puppet Data Service provides a centralized, highly available, API-driven interface for Puppet node data and for Hiera data. The data service supports self-service use cases, and Puppet-as-a-Service (PUPaaS) use cases, providing a foundational mechanism for allowing service customer teams to get work done without requiring manual work to be performed by the PUPaaS team.

The current repository presents a reference implementation of the Puppet Data Service Pattern and is backed by a Cassandra database.

This module contains:

* Classes to configure Cassandra cluster nodes for testing and development
* [Tasks](./tasks) to perform CRUD operations on data in the Puppet Data Service backend
* [Hiera 5 backend function](./lib/puppet/functions/puppet_data_service/data_hash.rb) for the Puppet data service
* [`trusted_external_command` integration](./files/get-nodedata.rb) for the Puppet Data Service

## Setup

1. Make sure this module and its dependencies (see [metadata.json](./metadata.json)) are added to your Puppetfile.
1. Set up Cassandra on at least one system by classifying it with the `puppet_data_service::cassandra` class.
1. Add the `puppet_data_service::puppetserver` class to the Puppet master, replica, and compilers.
1. Use the provided Bolt tasks to enter node, hiera, and/or environment data.

## Usage

### `trusted_external_command`

This module will deploy a ruby script `get-nodedata.rb` and configure it as the `trusted_external_command` in `puppet.conf`. Please note that when this setting is changed, the puppetserver service needs to be restarted.

This external command will be called by puppetserver twice per puppet run: once during pluginsync and once on catalog request. The script will be called with the certname of the node as the only argument. For example, suppose we just supplied these nodedata to the backend storage:
```
puppet task run puppet_data_service::node --params '{"op":"add", "name":"puppet.classroom.puppet.com", "puppet_classes": ["foo","bar","baz"], "puppet_environment":"penv", "userdata": {"key":"value","hash":{"key":"value"}}}' -n puppet.classroom.puppet.com
```
then, invoking the trusted external command should give:
```json
/etc/puppetlabs/puppet/get-nodedata.rb puppetclassroom.puppet.com
{
    "node":{
        "puppet_environment":"penv",
        "puppet_classes":["bar","baz","foo"],
        "userdata":{
            "key":"value",
            "hash":{
                "key":"value"
            }
        }
    }
}
```

### hiera backend

To use the PDS hiera backend, you will need to modify your hiera configuration file. It's entirely up to you which levels (`uris` in the below example) you configure. An example of the configuration (added under the existing one in `hiera.yaml`):

```yaml
  - name: 'Puppet Data Service data'
    data_hash: puppet_data_service::data_hash
    uris:
      - nodes/%{trusted.certname}
      - os/%{operatingsystem}
      - common
    options:
      hosts:
       - 10.160.0.50
```

where `10.160.0.50` happens to be the IP address of the Cassandra service.

If we populate our backend hiera data by defining a key `setting` with a value `setting value` on the `common` level like so:
```
puppet task run puppet_data_service::hiera --params='{"op": "set", "level": "common", "data":{"setting": "setting value"}}' -n puppet.classroom.puppet.com
```
Then we can perform a hiera lookup and we will find our setting:

```
$ hiera lookup setting --explain
... lines skipped ...
    Hierarchy entry "Puppet Data Service data"
      URI "nodes/puppet.classroom.puppet.com"
        Original uri: "nodes/%{trusted.certname}"
        No such key: "setting"
      URI "os/CentOS"
        Original uri: "os/%{operatingsystem}"
        No such key: "setting"
      URI "common"
        Original uri: "common"
        Found key: "setting" value: "setting value"
```

## Reference

### Schema

*nodedata* table

| Column             | Description                                                                          |
| :----------------- | :----------------------------------------------------------------------------------- |
| name               | node name, primary key                                                               |
| puppet_environment | the puppet code environment of the node                                              |
| puppet_classes     | the set of classes to be assigned to the node                                        |
| userdata           | arbitrary hash, available as trusted external fact (`facts["trusted']['external']` ) |

*hieradata* table

| Column | Description                             |
| :----- | :-------------------------------------- |
| level  | node name, part of primary key          |
| key    | key of the setting, part of primary key |
| value  | the value of the setting                |

### Tasks

```text
puppet_data_service::node - Perform data operations on Puppet node data

USAGE:
$ puppet task run puppet_data_service::node op=<value> [name=<value>] [puppet_classes=<value>] [puppet_environment=<value>] [userdata=<value>] <[--nodes, -n <node-names>] | [--query, -q <'query'>]>

PARAMETERS:
- op : Enum[list, show, add, modify, remove]
    Which operation to perform
- name : Optional[String]
    Which Puppet node to operate on
- puppet_classes : Optional[Array[String]]
    A list of classes for the node
- puppet_environment : Optional[String]
    The puppet environment to assign the node to
- userdata : Optional[Hash]
    A hash of user-specified data for the node
```

```
puppet_data_service::hiera - Perform data operations on Hiera data in the data service

USAGE:
$ puppet task run puppet_data_service::hiera op=<value> [data=<value>] [keys=<value>] [level=<value>] <[--nodes, -n <node-names>] | [--query, -q <'query'>]>

PARAMETERS:
- op : Enum[list, show, set, unset]
    Which operation to perform
- data : Optional[Hash[String, Data]]
    The hash of key/value pairs to set as data at the specified level
- keys : Optional[Array[String]]
    The array of key names to operate on
- level : Optional[String]
    The hiera level to operate on
You have new mail in /var/spool/mail/root
```

```
puppet_data_service::module - Perform data operations on modules in Puppet environments

USAGE:
$ puppet task run puppet_data_service::module op=<value> puppet_environment=<value> [name=<value>] [source=<value>] [type=<value>] [version=<value>] <[--nodes, -n <node-names>] | [--query, -q <'query'>]>

PARAMETERS:
- op : Enum[list, add, modify, remove]
    Which operation to perform
- puppet_environment : String
    Which Puppet environment to operate on
- name : Optional[String]
    Which module to operate on
- source : Optional[String]
    The source, e.g. git source clone URL, for the module
- type : Optional[Enum[git, forge]]
    The module type
- version : Optional[String]
    The version ref to deploy the module at
```

## Limitations

This repository is meant to provide a working example of a Puppet Data Service Pattern implementation. It is not meant nor suitable for unmodified production deployment.

## Development
