module Queries

  BAD_QUERIES = <<-eos
    SELECT
      query,
      full_scan,
      exec_count AS execution_count,
      total_latency AS total_exec_time,
      max_latency AS max_exec_time,
      avg_latency AS avg_exec_time
    FROM
      ps_helper.statement_analysis
    WHERE
      query IS NOT NULL
    LIMIT 10
  eos

  QUERIES_TMP_TABLES = <<-eos
    SELECT
      query,
      exec_count AS execution_count,
      memory_tmp_tables AS tmp_tables_in_memory,
      disk_tmp_tables AS tmp_tables_on_disk
    FROM
      ps_helper.statements_with_temp_tables
    LIMIT 10
  eos

  TABLE_STATS = <<-eos
    SELECT
      rows_fetched,
      fetch_latency,
      rows_inserted,
      insert_latency,
      rows_updated,
      update_latency,
      rows_deleted,
      delete_latency,
      innodb_buffer_pages
    FROM
      ps_helper.schema_table_statistics
    WHERE
      table_schema = ? AND table_name = ?
  eos

  INDEX_STATS = <<-eos
    SELECT
      index_name,
      rows_selected,
      rows_inserted,
      rows_updated,
      rows_deleted
    FROM
      ps_helper.schema_index_statistics
    WHERE
      table_schema = ? AND table_name = ?
  eos

  SCHEMA_SIZE = <<-eos
    SELECT
      count_tables AS table_count,
      count_views AS view_count,
      distinct_engines,
      ROUND(data_size / 1048576, 2) AS data_size_mb,
      ROUND(index_size / 1048576, 2) AS index_size_mb,
      ROUND(total_size / 1048576, 2) AS total_size_mb,
      largest_table,
      ROUND(largest_table_size / 1048576, 2) AS largest_table_size_mb
    FROM
      common_schema.data_size_per_schema
    WHERE
      table_schema = ?
  eos

  LOCK_USER = <<-eos
    CALL common_schema.eval("SELECT sql_block_account FROM common_schema.sql_accounts WHERE user = ?")
  eos

  UNLOCK_USER = <<-eos
    CALL common_schema.eval("SELECT sql_release_account FROM common_schema.sql_accounts WHERE user = ?")
  eos

  TRX_SUMMARY = <<-eos
    SELECT
      count_transactions AS total,
      running_transactions AS running,
      locked_transactions AS locked,
      distinct_locks
    FROM
      common_schema.innodb_transactions_summary
  eos

  ACTIVE_TRX = <<-eos
    SELECT
      trx_id AS id,
      trx_state AS state,
      trx_started AS started,
      trx_query AS query,
      CONCAT(trx_runtime_seconds, ' s') AS run_time,
      CONCAT(trx_wait_seconds, ' s') AS wait_time,
      CONCAT(trx_idle_seconds, ' s') AS idle_time
    FROM
      common_schema.innodb_transactions
  eos

  BLOCKED_TRX = <<-eos
    SELECT
      locked_trx_id AS id,
      locked_trx_started AS trx_started,
      locked_trx_wait_started AS wait_started,
      CONCAT(trx_wait_seconds, ' s') AS wait_time,
      locked_trx_query AS query,
      locking_trx_id AS blocking_id,
      locking_trx_started AS blocking_trx_started,
      locking_trx_query AS blocking_query
    FROM
      common_schema.innodb_locked_transactions
  eos

  KILL_IDLE_TRX = <<-eos
    CALL common_schema.eval("SELECT sql_kill_query FROM common_schema.innodb_transactions WHERE trx_idle_seconds >= ?")
  eos

  KILL_BLOCKING_TRX = <<-eos
    CALL common_schema.eval('SELECT sql_kill_blocking_query FROM common_schema.innodb_locked_transactions WHERE trx_wait_seconds >= ? GROUP BY sql_kill_blocking_query')
  eos

end
