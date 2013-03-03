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

# Hubot

A simple hubot script is provided (`hubot.mysql.coffee`) in the root directory showing how this 
service can be used from a hubot script.

Some examples of some of the commands from the hubot script being run
are shown below:

```
Hubot> hubot mysql active_trx db1
Hubot> { host: 'localhost', port: '9292', path: '/db1/active_trx' }
[{"id":"4379","state":"RUNNING","started":"2013-03-03 17:42:49-0500","query":null,"run_time":"578 s","wait_time":null,"idle_time":"498
s"},{"id":"4378","state":"RUNNING","started":"2013-03-03 17:42:29-0500","query":null,"run_time":"598 s","wait_time":null,"idle_time":"203
s"}]
Hubot>
 
Hubot> hubot mysql kill_idle_trx db1 10
Hubot> { host: 'localhost',
  port: '9292',
  path: '/db1/kill_idle_trx/10' }
{"status":"ok"}
Hubot>
 
Hubot> { host: 'localhost', port: '9292', path: '/db1/trx_summary' }
[{"total":2,"running":"0.1E1","locked":"0.1E1","distinct_locks":1}]
Hubot>
 
Hubot> hubot mysql bad_queries db1
Hubot> { host: 'localhost', port: '9292', path: '/db1/bad_queries' }
[{"query":"UPDATE `t1` SET `c2` = ? WHERE `c1` = ?
","full_scan":"","execution_count":3,"total_exec_time":"00:01:42.1666","max_exec_time":"51.09s","avg_exec_time":"34.06 s"},{"query":"INSERT INTO `common_schema` .
`help_content` VALUES (...)","full_scan":"","execution_count":138,"total_exec_time":"1.73 s","max_exec_time":"1.12 s","avg_exec_time":"12.55 ms"},{"query":"SELECT `rows_fetched` , `fetch ... M ( `fsbi` . `COUNT_WRITE`
...","full_scan":"*","execution_count":4,"total_exec_time":"1.47 s","max_exec_time":"768.98 ms","avg_exec_time":"367.15
ms"},{"query":"CALL `run` ( @ ? )","full_scan":"","execution_count":6,"total_exec_time":"1.05 s","max_exec_time":"248.93 ms","avg_exec_time":"175.80
ms"},{"query":"SELECT `count_tables` AS `tabl ... ation_schema` . `tables` ....","full_scan":"*","execution_count":1,"total_exec_time":"810.64
ms","max_exec_time":"810.64 ms","avg_exec_time":"810.64 ms"},{"query":"CREATE TABLE `t1` ( `c1` INTEGER , `c2` VARCHARACTER (?)
) ","full_scan":"","execution_count":1,"total_exec_time":"655.27 ms","max_exec_time":"655.27 ms","avg_exec_time":"655.27
ms"},{"query":"SELECT `count_tables` AS `tabl ... ENGTH` ) ) AS `total_size`
...","full_scan":"*","execution_count":3,"total_exec_time":"630.96
ms","max_exec_time":"518.33 ms","avg_exec_time":"210.32
ms"},{"query":"CALL `common_schema` . `eval` (?)
","full_scan":"","execution_count":3,"total_exec_time":"625.82
ms","max_exec_time":"445.78 ms","avg_exec_time":"208.61
ms"},{"query":"CREATE VIEW `top_global_io_con ... ` > ? ORDER BY
`ewsgben` .
...","full_scan":"","execution_count":2,"total_exec_time":"501.51
ms","max_exec_time":"300.71 ms","avg_exec_time":"250.76
ms"},{"query":"CREATE VIEW `top_global_consum ... ) / SUM ( `COUNT_STAR`
) DESC ","full_scan":"","execution_count":2,"total_exec_time":"466.11
ms","max_exec_time":"244.76 ms","avg_exec_time":"233.06 ms"}]
Hubot> 
 
Hubot> hubot mysql queries_tmp_tables db1
Hubot> { host: 'localhost',
  port: '9292',
  path: '/db1/queries_tmp_tables' }
[{"query":"SELECT `count_tables` AS `tabl ... ENGTH` ) ) AS `total_size`
...","execution_count":3,"tmp_tables_in_memory":888,"tmp_tables_on_disk":135},{"query":"SELECT
`count_tables` AS `tabl ... ation_schema` . `tables` .
...","execution_count":1,"tmp_tables_in_memory":296,"tmp_tables_on_disk":45},{"query":"SELECT
COUNT ( * ) AS `count`  ... . `plugins` ) AS `t1` LIMIT ?
","execution_count":21,"tmp_tables_in_memory":42,"tmp_tables_on_disk":42},{"query":"SELECT
* FROM `information_schema` . `plugins`
","execution_count":25,"tmp_tables_in_memory":25,"tmp_tables_on_disk":25},{"query":"SELECT
`trx_id` AS `id` , `trx ... AS `trx_operation_state` ,
...","execution_count":11,"tmp_tables_in_memory":22,"tmp_tables_on_disk":11},{"query":"SELECT
`rows_fetched` , `fetch ... M ( `fsbi` . `COUNT_WRITE`
...","execution_count":4,"tmp_tables_in_memory":24,"tmp_tables_on_disk":4},{"query":"SELECT
`_sql_range_partitions_ ... e_partitions_beautified` .
...","execution_count":1,"tmp_tables_in_memory":9,"tmp_tables_on_disk":4},{"query":"SELECT
`_sql_range_partitions_ ...  `concat` ( ? , `ifnull` (
...","execution_count":1,"tmp_tables_in_memory":8,"tmp_tables_on_disk":3},{"query":"CREATE
OR REPLACE ALGORITHM =  ... ition_description` ) , ? ,
...","execution_count":1,"tmp_tables_in_memory":8,"tmp_tables_on_disk":3},{"query":"SELECT
`_sql_range_partitions_ ... l_range_partitions_diff` .
...","execution_count":1,"tmp_tables_
```

# TODO

* parse JSON in hubot script and format output nicely
* more error checking.
* restrict some operations to only be allowed to be performed on a slave
* replication load average endpoint
* backup / restore information & testing
