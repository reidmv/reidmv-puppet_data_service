# Puppet Data Service Pattern & Reference Implementation

#### Table of Contents

1. [Description](#description)
2. [Setup - The basics of getting started with puppet\_data\_service](#setup)
    * [What puppet\_data\_service affects](#what-puppet_data_service-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with puppet\_data\_service](#beginning-with-puppet_data_service)
3. [Usage - Configuration options and additional functionality](#usage)
4. [Limitations - OS compatibility, etc.](#limitations)
5. [Development - Guide for contributing to the module](#development)

## Description

The Puppet data service provides a centralized, highly available, API-driven interface for Puppet node data and for Hiera data. The data service supports self-service use cases, and Puppet-as-a-Service (PUPaaS) use cases, providing a foundational mechanism for allowing service customer teams to get work done without requiring manual work to be performed by the PUPaaS team.

The data service is backed by a Cassandra database.

This module contains:

* Classes to configure Cassandra cluster nodes for testing and development
* Tasks for initializing a Cassandra schema for the Puppet data service
* Tasks to perform CRUD operations on data in the Puppet data service
* Hiera 5 backend for the Puppet data service
* `trusted_external_command` integration for the Puppet data service

## Setup

### Setup Requirements

`puppetserver gem install cassandra-driver`

### Beginning with puppet\_data\_service

The very basic steps needed for a user to get the module up and running.

1. Set up Cassandra on at least one system by classifying it with the `puppet_data_service::cassandra` class.
2. Add the `puppet_data_service::puppetserver` class to the Puppet master, replica, and compilers.
3. Use the provided Bolt tasks to enter node, hiera, and/or environment data

## Usage

Include usage examples for common use cases in the **Usage** section. Show your users how to use your module to solve problems, and be sure to include code examples. Include three to five examples of the most important or common tasks a user can accomplish with your module. Show users how to accomplish more complex tasks that involve different types, classes, and functions working in tandem.

## Reference

〰〰〰〰〰 〰〰〰 〰〰〰〰

## Limitations

〰〰〰〰〰 〰〰〰 〰〰〰〰

## Development

〰〰〰〰〰 〰〰〰 〰〰〰〰
