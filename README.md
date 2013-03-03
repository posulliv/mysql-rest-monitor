# Overview

Ths is a simple REST service exposing a number of endpoints to provide
information about running MySQL instances. For collecting information
from MySQL, features from the `performance_schema` first introduced in
MySQL 5.5 are used. Features from `performance_schema` that are only
available from MySQL 5.6 onwards are also used. Thus, this service is
currently only usable with MySQL 5.6.

# API

The API is documented using apiary. It can be viewed at the address
below:

http://docs.mysql.apiary.io/

# Configuring Database Servers

In the `servers.rb` file is a sample configuration. In the `masters` and
`slaves` hash, place information on the servers you wish to be to able
to communicate with. The key for each server in this hash is what will
be used to identify a database server when talking with the API.

For example, if you have a simple environment with 1 master server and 2
slaves, your `servers.rb` file might look something like:

```
$default = "mysql2://root@localhost/"
$slaves = {
  :slave1 => { :host => "db2" },
  :slave2 => { :host => "db3" }
}
$masters = {
  :master1 => { :host => "db1" }
}
```

To issue an API call to the master server:

```
$ curl -X GET http://localhost:9292/master1/schema_size/test | jq "."
[
  {
    "largest_table_size_mb": "0.152E1",
    "largest_table": "help_content",
    "total_size_mb": "0.172E1",
    "index_size_mb": "0.2E-1",
    "data_size_mb": "0.17E1",
    "distinct_engines": 1,
    "view_count": "0.52E2",
    "table_count": "0.6E1"
  }
]
$ 
```

# Install SQL Scripts on Monitored Database Servers

This service uses
[common_schema](http://code.google.com/p/common-schema/) and
[ps_helper](http://www.markleith.co.uk/ps_helper/). On any database
server that this service will be talking to, you will need to install
the SQL scripts in this repository for installing these components.

```
mysql -u USER -p -h HOST < ps_55.sql
mysql -u USER -p -h HOST < ps_56.sql
mysql -u USER -p -h HOST < common_schema-1.3.1.sql
```

# Running

```
bundle install
bundle exec rackup
```

