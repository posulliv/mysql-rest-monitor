SET NAMES utf8;

CREATE DATABASE IF NOT EXISTS ps_helper DEFAULT CHARACTER SET utf8;

USE ps_helper;

/*
 * Function: format_bytes()
 * 
 * Takes a raw bytes value, and converts it to a human readable form
 *
 * Parameters
 *   bytes: The raw bytes value to convert
 *
 * mysql> select format_bytes(2348723492723746);
 * +--------------------------------+
 * | format_bytes(2348723492723746) |
 * +--------------------------------+
 * | 2.09 PiB                       |
 * +--------------------------------+
 * 1 row in set (0.00 sec)
 * 
 * mysql> select format_bytes(2348723492723);
 * +-----------------------------+
 * | format_bytes(2348723492723) |
 * +-----------------------------+
 * | 2.14 TiB                    |
 * +-----------------------------+
 * 1 row in set (0.00 sec)
 * 
 * mysql> select format_bytes(23487234);
 * +------------------------+
 * | format_bytes(23487234) |
 * +------------------------+
 * | 22.40 MiB              |
 * +------------------------+
 * 1 row in set (0.00 sec)
 */
DROP FUNCTION IF EXISTS format_bytes;

DELIMITER $$

CREATE FUNCTION format_bytes(bytes BIGINT)
  RETURNS VARCHAR(16) DETERMINISTIC
BEGIN
  IF bytes IS NULL THEN RETURN NULL;
  ELSEIF bytes >= 1125899906842624 THEN RETURN CONCAT(ROUND(bytes / 1125899906842624, 2), ' PiB');
  ELSEIF bytes >= 1099511627776 THEN RETURN CONCAT(ROUND(bytes / 1099511627776, 2), ' TiB');
  ELSEIF bytes >= 1073741824 THEN RETURN CONCAT(ROUND(bytes / 1073741824, 2), ' GiB');
  ELSEIF bytes >= 1048576 THEN RETURN CONCAT(ROUND(bytes / 1048576, 2), ' MiB');
  ELSEIF bytes >= 1024 THEN RETURN CONCAT(ROUND(bytes / 1024, 2), ' KiB');
  ELSE RETURN CONCAT(bytes, ' bytes');
  END IF;
END $$

DELIMITER ;

/*
 * Function: format_time()
 * 
 * Takes a raw picoseconds value, and converts it to a human readable form.
 * Picoseconds are the precision that all latency values are printed in 
 * within MySQL's Performance Schema.
 *
 * Parameters
 *   picoseconds: The raw picoseconds value to convert
 *
 * mysql> select format_time(342342342342345);
 * +------------------------------+
 * | format_time(342342342342345) |
 * +------------------------------+
 * | 00:05:42                     |
 * +------------------------------+
 * 1 row in set (0.00 sec)
 * 
 * mysql> select format_time(342342342);
 * +------------------------+
 * | format_time(342342342) |
 * +------------------------+
 * | 342.34 µs              |
 * +------------------------+
 * 1 row in set (0.00 sec)
 * 
 * mysql> select format_time(34234);
 * +--------------------+
 * | format_time(34234) |
 * +--------------------+
 * | 34.23 ns           |
 * +--------------------+
 * 1 row in set (0.00 sec)
 * 
 * mysql> select format_time(342);
 * +------------------+
 * | format_time(342) |
 * +------------------+
 * | 342 ps           |
 * +------------------+
 * 1 row in set (0.00 sec)
 */
DROP FUNCTION IF EXISTS format_time;

DELIMITER $$

CREATE FUNCTION format_time(picoseconds BIGINT)
  RETURNS VARCHAR(16) CHARSET UTF8 DETERMINISTIC
BEGIN
  IF picoseconds IS NULL THEN RETURN NULL;
  ELSEIF picoseconds >= 60000000000000 THEN RETURN SEC_TO_TIME(picoseconds/1000000000000);
  ELSEIF picoseconds >= 1000000000000 THEN RETURN CONCAT(ROUND(picoseconds / 1000000000000, 2), ' s');
  ELSEIF picoseconds >= 1000000000 THEN RETURN CONCAT(ROUND(picoseconds / 1000000000, 2), ' ms');
  ELSEIF picoseconds >= 1000000 THEN RETURN CONCAT(ROUND(picoseconds / 1000000, 2), ' µs');
  ELSEIF picoseconds >= 1000 THEN RETURN CONCAT(ROUND(picoseconds / 1000, 2), ' ns');
  ELSE RETURN CONCAT(picoseconds, ' ps');
  END IF;
END $$

DELIMITER ;

/*
 * Function: format_path()
 * 
 * Takes a raw path value, and strips out the datadir or tmpdir
 * replacing with @@datadir and @@tmpdir respectively. 
 *
 * Also normalizes the paths across operating systems, so backslashes
 * on Windows are converted to forward slashes
 *
 * Parameters
 *   path: The raw file path value to format
 *
 * mysql> select @@datadir;
 * +-----------------------------------------------+
 * | @@datadir                                     |
 * +-----------------------------------------------+
 * | /Users/mark/sandboxes/SmallTree/AMaster/data/ |
 * +-----------------------------------------------+
 * 1 row in set (0.06 sec)
 * 
 * mysql> select format_path('/Users/mark/sandboxes/SmallTree/AMaster/data/mysql/proc.MYD');
 * +----------------------------------------------------------------------------+
 * | format_path('/Users/mark/sandboxes/SmallTree/AMaster/data/mysql/proc.MYD') |
 * +----------------------------------------------------------------------------+
 * | @@datadir/mysql/proc.MYD                                                   |
 * +----------------------------------------------------------------------------+
 * 1 row in set (0.03 sec)
 */

DROP FUNCTION IF EXISTS format_path;

DELIMITER $$

CREATE FUNCTION format_path(path VARCHAR(260))
  RETURNS VARCHAR(260) CHARSET UTF8 DETERMINISTIC
BEGIN
  DECLARE v_path VARCHAR(260);

  /* OSX hides /private/ in variables, but Performance Schema does not */
  IF path LIKE '/private/%' 
  THEN SET v_path = REPLACE(path, '/private', '');
  ELSE SET v_path = path;
  END IF;

  IF v_path IS NULL THEN RETURN NULL;
  ELSEIF v_path LIKE CONCAT(@@global.datadir, '%') ESCAPE '|' THEN 
    RETURN REPLACE(REPLACE(REPLACE(v_path, @@global.datadir, '@@datadir/'), '\\\\', ''), '\\', '/');
  ELSEIF v_path LIKE CONCAT(@@global.tmpdir, '%') ESCAPE '|' THEN 
    RETURN REPLACE(REPLACE(REPLACE(v_path, @@global.tmpdir, '@@tmpdir/'), '\\\\', ''), '\\', '/');
  ELSE RETURN v_path;
  END IF;
END$$

DELIMITER ;

/*
 * Function: extract_schema_from_file_name()
 * 
 * Takes a raw file path, and extracts the schema name from it
 *
 * Parameters
 *   filename: The raw file name value to extract the schema name from
 */
DROP FUNCTION IF EXISTS extract_schema_from_file_name;

DELIMITER $$

CREATE FUNCTION extract_schema_from_file_name(filename VARCHAR(512))
  RETURNS VARCHAR(64) DETERMINISTIC
  RETURN substring_index(replace(filename, @@global.datadir, ''), '\\', 1);
$$

DELIMITER ;

/*
 * Function: extract_table_from_file_name()
 * 
 * Takes a raw file path, and extracts the table name from it
 *
 * Parameters
 *   filename: The raw file name value to extract the table name from
 */
DROP FUNCTION IF EXISTS extract_table_from_file_name;

DELIMITER $$

CREATE FUNCTION extract_table_from_file_name(filename VARCHAR(512))
  RETURNS VARCHAR(64) DETERMINISTIC
  RETURN substring_index(replace(substring_index(replace(filename, @@global.datadir, ''), '\\', -1), '@0024', '$'), '.', 1);
$$

DELIMITER ;

/*
 * View: latest_file_io
 *
 * Latest file IO, by file / thread
 *
 * Versions: 5.5+
 *
 * mysql> select * from latest_file_io limit 10;
 * +----------------------+----------------------------------------+------------+-----------+-----------+
 * | thread               | file                                   | latency    | operation | requested |
 * +----------------------+----------------------------------------+------------+-----------+-----------+
 * | msandbox@localhost:1 | @@tmpdir/#sqlcf28_1_4e.MYI             | 9.26 µs    | write     | 124 bytes |
 * | msandbox@localhost:1 | @@tmpdir/#sqlcf28_1_4e.MYI             | 4.00 µs    | write     | 2 bytes   |
 * | msandbox@localhost:1 | @@tmpdir/#sqlcf28_1_4e.MYI             | 56.34 µs   | close     | NULL      |
 * | msandbox@localhost:1 | @@tmpdir/#sqlcf28_1_4e.MYD             | 53.93 µs   | close     | NULL      |
 * | msandbox@localhost:1 | @@tmpdir/#sqlcf28_1_4e.MYI             | 104.05 ms  | delete    | NULL      |
 * | msandbox@localhost:1 | @@tmpdir/#sqlcf28_1_4e.MYD             | 661.18 µs  | delete    | NULL      |
 * | msandbox@localhost:1 | @@datadir/Cerberus.log                 | 35.99 ms   | write     | 57 bytes  |
 * | msandbox@localhost:1 | @@datadir/ps_helper/latest_file_io.frm | 7.40 µs    | stat      | NULL      |
 * | msandbox@localhost:1 | @@datadir/ps_helper/latest_file_io.frm | 9.81 µs    | open      | NULL      |
 * | msandbox@localhost:1 | @@datadir/ps_helper/latest_file_io.frm | 16.06 µs   | read      | 3.17 KiB  |
 * +----------------------+----------------------------------------+------------+-----------+-----------+
 * 10 rows in set (0.05 sec)
 */

DROP VIEW IF EXISTS latest_file_io;

CREATE VIEW latest_file_io AS
SELECT IF(id IS NULL, 
             CONCAT(SUBSTRING_INDEX(name, '/', -1), ':', thread_id), 
             CONCAT(user, '@', host, ':', id)
          ) thread, 
       format_path(object_name) file, 
       format_time(timer_wait) AS latency, 
       operation, 
       format_bytes(number_of_bytes) AS requested
  FROM performance_schema.events_waits_history_long 
  JOIN performance_schema.threads USING (thread_id)
  LEFT JOIN information_schema.processlist ON processlist_id = id
 WHERE object_name IS NOT NULL
 ORDER BY timer_start;

/*
 * View: top_global_consumers_by_avg_latency
 * 
 * Lists the top wait classes by average latency
 * 
 * Versions: 5.5+
 *
 * mysql> select * from top_global_consumers_by_avg_latency where event_class != 'idle';
 * +-------------------+--------------+---------------+-------------+-------------+-------------+
 * | event_class       | total_events | total_latency | min_latency | avg_latency | max_latency |
 * +-------------------+--------------+---------------+-------------+-------------+-------------+
 * | wait/io/file      |       543123 | 44.60 s       | 19.44 ns    | 82.11 µs    | 4.21 s      |
 * | wait/io/table     |        22002 | 766.60 ms     | 148.72 ns   | 34.84 µs    | 44.97 ms    |
 * | wait/io/socket    |        79613 | 967.17 ms     | 0 ps        | 12.15 µs    | 27.10 ms    |
 * | wait/lock/table   |        35409 | 18.68 ms      | 65.45 ns    | 527.51 ns   | 969.88 µs   |
 * | wait/synch/rwlock |        37935 | 4.61 ms       | 21.38 ns    | 121.61 ns   | 34.65 µs    |
 * | wait/synch/mutex  |       390622 | 18.60 ms      | 19.44 ns    | 47.61 ns    | 10.32 µs    |
 * +-------------------+--------------+---------------+-------------+-------------+-------------+
 * 6 rows in set (0.03 sec)
 *
 * (Example from 5.6.6)
 */

DROP VIEW IF EXISTS top_global_consumers_by_avg_latency;

CREATE VIEW top_global_consumers_by_avg_latency AS
SELECT SUBSTRING_INDEX(event_name,'/', 3) event_class,
       SUM(COUNT_STAR) total_events,
       format_time(SUM(sum_timer_wait)) total_latency,
       format_time(MIN(min_timer_wait)) min_latency,
       format_time(SUM(sum_timer_wait) / SUM(COUNT_STAR)) avg_latency,
       format_time(MAX(max_timer_wait)) max_latency
  FROM performance_schema.events_waits_summary_global_by_event_name
 WHERE sum_timer_wait > 0
 GROUP BY SUBSTRING_INDEX(event_name,'/', 3) 
 ORDER BY SUM(sum_timer_wait) / SUM(COUNT_STAR) DESC;

/*
 * View: top_global_consumers_by_total_latency
 * 
 * Lists the top wait classes by total latency
 * 
 * Versions: 5.5+
 *
 * mysql> select * from top_global_consumers_by_total_latency where event_class != 'idle';
 * +-------------------+--------------+---------------+-------------+-------------+-------------+
 * | event_class       | total_events | total_latency | min_latency | avg_latency | max_latency |
 * +-------------------+--------------+---------------+-------------+-------------+-------------+
 * | wait/io/file      |       550470 | 46.01 s       | 19.44 ns    | 83.58 µs    | 4.21 s      |
 * | wait/io/socket    |       228833 | 2.71 s        | 0 ps        | 11.86 µs    | 29.93 ms    |
 * | wait/io/table     |        64063 | 1.89 s        | 99.79 ns    | 29.43 µs    | 68.07 ms    |
 * | wait/lock/table   |        76029 | 47.19 ms      | 65.45 ns    | 620.74 ns   | 969.88 µs   |
 * | wait/synch/mutex  |       635925 | 34.93 ms      | 19.44 ns    | 54.93 ns    | 107.70 µs   |
 * | wait/synch/rwlock |        61287 | 7.62 ms       | 21.38 ns    | 124.37 ns   | 34.65 µs    |
 * +-------------------+--------------+---------------+-------------+-------------+-------------+
 *
 * (Example from 5.6.6)
 */

DROP VIEW IF EXISTS top_global_consumers_by_total_latency;

CREATE VIEW top_global_consumers_by_total_latency AS
SELECT SUBSTRING_INDEX(event_name,'/', 3) event_class, 
       SUM(COUNT_STAR) total_events,
       format_time(SUM(sum_timer_wait)) total_latency,
       format_time(MIN(min_timer_wait)) min_latency,
       format_time(SUM(sum_timer_wait) / SUM(COUNT_STAR)) avg_latency,
       format_time(MAX(max_timer_wait)) max_latency
  FROM performance_schema.events_waits_summary_global_by_event_name
 WHERE sum_timer_wait > 0
 GROUP BY SUBSTRING_INDEX(event_name,'/', 3) 
 ORDER BY SUM(sum_timer_wait) DESC;

/*
 * View: top_global_io_consumers_by_latency
 *
 * Show the top global IO consumers by latency
 *
 * Versions: 5.5+
 *
 * mysql> select * from top_global_io_consumers_by_latency;
 * +--------------------+------------+---------------+-------------+-------------+-------------+------------+------------+-----------+-------------+---------------+-------------+
 * | event_name         | count_star | total_latency | min_latency | avg_latency | max_latency | count_read | total_read | avg_read  | count_write | total_written | avg_written |
 * +--------------------+------------+---------------+-------------+-------------+-------------+------------+------------+-----------+-------------+---------------+-------------+
 * | sql/dbopt          |     328812 | 26.93 s       | 2.06 µs     | 81.90 µs    | 178.71 ms   |          0 | 0 bytes    | 0 bytes   |           9 | 585 bytes     | 65 bytes    |
 * | sql/FRM            |      57837 | 8.39 s        | 19.44 ns    | 145.13 µs   | 336.71 ms   |       8009 | 2.60 MiB   | 341 bytes |       14675 | 2.91 MiB      | 208 bytes   |
 * | sql/binlog         |        190 | 6.79 s        | 1.56 µs     | 35.76 ms    | 4.21 s      |         52 | 60.54 KiB  | 1.16 KiB  |           0 | 0 bytes       | 0 bytes     |
 * | sql/ERRMSG         |          5 | 2.03 s        | 8.61 µs     | 405.40 ms   | 2.03 s      |          3 | 51.82 KiB  | 17.27 KiB |           0 | 0 bytes       | 0 bytes     |
 * | myisam/dfile       |     163681 | 983.13 ms     | 379.08 ns   | 6.01 µs     | 22.06 ms    |      68721 | 127.23 MiB | 1.90 KiB  |     1011613 | 121.45 MiB    | 126 bytes   |
 * | sql/file_parser    |        419 | 601.37 ms     | 1.96 µs     | 1.44 ms     | 37.14 ms    |         66 | 42.01 KiB  | 652 bytes |          64 | 226.98 KiB    | 3.55 KiB    |
 * | myisam/kfile       |       1775 | 375.13 ms     | 1.02 µs     | 211.34 µs   | 35.15 ms    |      54034 | 9.97 MiB   | 193 bytes |      428001 | 12.39 MiB     | 30 bytes    |
 * | sql/global_ddl_log |        164 | 75.96 ms      | 5.72 µs     | 463.19 µs   | 7.43 ms     |         20 | 80.00 KiB  | 4.00 KiB  |          76 | 304.00 KiB    | 4.00 KiB    |
 * | sql/partition      |         81 | 18.87 ms      | 888.08 ns   | 232.92 µs   | 4.67 ms     |         66 | 2.75 KiB   | 43 bytes  |           8 | 288 bytes     | 36 bytes    |
 * | sql/misc           |         23 | 2.73 ms       | 65.14 µs    | 118.50 µs   | 255.31 µs   |          0 | 0 bytes    | 0 bytes   |           0 | 0 bytes       | 0 bytes     |
 * | sql/relaylog       |          7 | 1.18 ms       | 838.84 ns   | 168.30 µs   | 892.70 µs   |          0 | 0 bytes    | 0 bytes   |           1 | 120 bytes     | 120 bytes   |
 * | sql/binlog_index   |          5 | 593.47 µs     | 1.07 µs     | 118.69 µs   | 535.90 µs   |          0 | 0 bytes    | 0 bytes   |           0 | 0 bytes       | 0 bytes     |
 * | sql/pid            |          3 | 220.55 µs     | 29.29 µs    | 73.52 µs    | 143.11 µs   |          0 | 0 bytes    | 0 bytes   |           1 | 5 bytes       | 5 bytes     |
 * | mysys/charset      |          3 | 196.52 µs     | 17.61 µs    | 65.51 µs    | 137.33 µs   |          1 | 17.83 KiB  | 17.83 KiB |           0 | 0 bytes       | 0 bytes     |
 * | mysys/cnf          |          5 | 171.61 µs     | 303.26 ns   | 34.32 µs    | 115.21 µs   |          3 | 56 bytes   | 19 bytes  |           0 | 0 bytes       | 0 bytes     |
 * | sql/casetest       |          1 | 121.19 µs     | 121.19 µs   | 121.19 µs   | 121.19 µs   |          0 | 0 bytes    | 0 bytes   |           0 | 0 bytes       | 0 bytes     |
 * +--------------------+------------+---------------+-------------+-------------+-------------+------------+------------+-----------+-------------+---------------+-------------+
 *
 * (Example from 5.6.6)
 */

DROP VIEW IF EXISTS top_global_io_consumers_by_latency;

CREATE VIEW top_global_io_consumers_by_latency AS
SELECT SUBSTRING_INDEX(event_name, '/', -2) event_name,
       ewsgben.count_star,
       format_time(ewsgben.sum_timer_wait) total_latency,
       format_time(ewsgben.min_timer_wait) min_latency,
       format_time(ewsgben.avg_timer_wait) avg_latency,
       format_time(ewsgben.max_timer_wait) max_latency,
       count_read,
       format_bytes(sum_number_of_bytes_read) total_read,
       format_bytes(IFNULL(sum_number_of_bytes_read / count_read, 0)) avg_read,
       count_write,
       format_bytes(sum_number_of_bytes_write) total_written,
       format_bytes(IFNULL(sum_number_of_bytes_write / count_write, 0)) avg_written
  FROM performance_schema.events_waits_summary_global_by_event_name AS ewsgben
  JOIN performance_schema.file_summary_by_event_name AS fsben USING (event_name) 
 WHERE event_name LIKE 'wait/io/file/%'
   AND ewsgben.count_star > 0
 ORDER BY ewsgben.sum_timer_wait DESC;

/*
 * View: top_global_io_consumers_by_bytes_usage
 *
 * Show the top global IO consumer classes by bytes usage
 *
 * Versions: 5.5+
 *
 * mysql> select * from top_global_io_consumers_by_bytes_usage;
 * +--------------------+------------+---------------+-------------+-------------+-------------+------------+------------+-----------+-------------+---------------+-------------+-----------------+
 * | event_name         | count_star | total_latency | min_latency | avg_latency | max_latency | count_read | total_read | avg_read  | count_write | total_written | avg_written | total_requested |
 * +--------------------+------------+---------------+-------------+-------------+-------------+------------+------------+-----------+-------------+---------------+-------------+-----------------+
 * | myisam/dfile       |     163681 | 983.13 ms     | 379.08 ns   | 6.01 µs     | 22.06 ms    |      68737 | 127.31 MiB | 1.90 KiB  |     1012221 | 121.52 MiB    | 126 bytes   | 248.83 MiB      |
 * | myisam/kfile       |       1775 | 375.13 ms     | 1.02 µs     | 211.34 µs   | 35.15 ms    |      54066 | 9.97 MiB   | 193 bytes |      428257 | 12.40 MiB     | 30 bytes    | 22.37 MiB       |
 * | sql/FRM            |      57889 | 8.40 s        | 19.44 ns    | 145.05 µs   | 336.71 ms   |       8009 | 2.60 MiB   | 341 bytes |       14675 | 2.91 MiB      | 208 bytes   | 5.51 MiB        |
 * | sql/global_ddl_log |        164 | 75.96 ms      | 5.72 µs     | 463.19 µs   | 7.43 ms     |         20 | 80.00 KiB  | 4.00 KiB  |          76 | 304.00 KiB    | 4.00 KiB    | 384.00 KiB      |
 * | sql/file_parser    |        419 | 601.37 ms     | 1.96 µs     | 1.44 ms     | 37.14 ms    |         66 | 42.01 KiB  | 652 bytes |          64 | 226.98 KiB    | 3.55 KiB    | 268.99 KiB      |
 * | sql/binlog         |        190 | 6.79 s        | 1.56 µs     | 35.76 ms    | 4.21 s      |         52 | 60.54 KiB  | 1.16 KiB  |           0 | 0 bytes       | 0 bytes     | 60.54 KiB       |
 * | sql/ERRMSG         |          5 | 2.03 s        | 8.61 µs     | 405.40 ms   | 2.03 s      |          3 | 51.82 KiB  | 17.27 KiB |           0 | 0 bytes       | 0 bytes     | 51.82 KiB       |
 * | mysys/charset      |          3 | 196.52 µs     | 17.61 µs    | 65.51 µs    | 137.33 µs   |          1 | 17.83 KiB  | 17.83 KiB |           0 | 0 bytes       | 0 bytes     | 17.83 KiB       |
 * | sql/partition      |         81 | 18.87 ms      | 888.08 ns   | 232.92 µs   | 4.67 ms     |         66 | 2.75 KiB   | 43 bytes  |           8 | 288 bytes     | 36 bytes    | 3.04 KiB        |
 * | sql/dbopt          |     329166 | 26.95 s       | 2.06 µs     | 81.89 µs    | 178.71 ms   |          0 | 0 bytes    | 0 bytes   |           9 | 585 bytes     | 65 bytes    | 585 bytes       |
 * | sql/relaylog       |          7 | 1.18 ms       | 838.84 ns   | 168.30 µs   | 892.70 µs   |          0 | 0 bytes    | 0 bytes   |           1 | 120 bytes     | 120 bytes   | 120 bytes       |
 * | mysys/cnf          |          5 | 171.61 µs     | 303.26 ns   | 34.32 µs    | 115.21 µs   |          3 | 56 bytes   | 19 bytes  |           0 | 0 bytes       | 0 bytes     | 56 bytes        |
 * | sql/pid            |          3 | 220.55 µs     | 29.29 µs    | 73.52 µs    | 143.11 µs   |          0 | 0 bytes    | 0 bytes   |           1 | 5 bytes       | 5 bytes     | 5 bytes         |
 * | sql/casetest       |          1 | 121.19 µs     | 121.19 µs   | 121.19 µs   | 121.19 µs   |          0 | 0 bytes    | 0 bytes   |           0 | 0 bytes       | 0 bytes     | 0 bytes         |
 * | sql/binlog_index   |          5 | 593.47 µs     | 1.07 µs     | 118.69 µs   | 535.90 µs   |          0 | 0 bytes    | 0 bytes   |           0 | 0 bytes       | 0 bytes     | 0 bytes         |
 * | sql/misc           |         23 | 2.73 ms       | 65.14 µs    | 118.50 µs   | 255.31 µs   |          0 | 0 bytes    | 0 bytes   |           0 | 0 bytes       | 0 bytes     | 0 bytes         |
 * +--------------------+------------+---------------+-------------+-------------+-------------+------------+------------+-----------+-------------+---------------+-------------+-----------------+
 *
 * (Example from 5.6.6)
 */

DROP VIEW IF EXISTS top_global_io_consumers_by_bytes_usage;

CREATE VIEW top_global_io_consumers_by_bytes_usage AS
SELECT SUBSTRING_INDEX(event_name, '/', -2) event_name,
       ewsgben.count_star,
       format_time(ewsgben.sum_timer_wait) total_latency,
       format_time(ewsgben.min_timer_wait) min_latency,
       format_time(ewsgben.avg_timer_wait) avg_latency,
       format_time(ewsgben.max_timer_wait) max_latency,
       count_read,
       format_bytes(sum_number_of_bytes_read) total_read,
       format_bytes(IFNULL(sum_number_of_bytes_read / count_read, 0)) avg_read,
       count_write,
       format_bytes(sum_number_of_bytes_write) total_written,
       format_bytes(IFNULL(sum_number_of_bytes_write / count_write, 0)) avg_written,
       format_bytes(sum_number_of_bytes_write + sum_number_of_bytes_read) total_requested
  FROM performance_schema.events_waits_summary_global_by_event_name AS ewsgben
  JOIN performance_schema.file_summary_by_event_name AS fsben USING (event_name) 
 WHERE event_name LIKE 'wait/io/file/%' 
   AND ewsgben.count_star > 0
 ORDER BY sum_number_of_bytes_write + sum_number_of_bytes_read DESC;

/*
 * View: top_io_by_file
 *
 * Show the top global IO consumers by bytes usage by file
 *
 * Versions: 5.5+
 *
 * mysql> select * from top_io_by_file limit 10;
 * +-------------------------------------------------+------------+------------+-----------+-------------+---------------+-----------+------------+-----------+
 * | file                                            | count_read | total_read | avg_read  | count_write | total_written | avg_write | total      | write_pct |
 * +-------------------------------------------------+------------+------------+-----------+-------------+---------------+-----------+------------+-----------+
 * | @@datadir/mysql/user.MYD                        |      44829 | 21.61 MiB  | 505 bytes |           0 | 0 bytes       | 0 bytes   | 21.61 MiB  |      0.00 |
 * | @@datadir/mem/#sql-82c_2e.frm                   |       1932 | 562.54 KiB | 298 bytes |        5547 | 591.51 KiB    | 109 bytes | 1.13 MiB   |     51.26 |
 * | @@datadir/mem/#sql-82c_42.frm                   |        952 | 488.38 KiB | 525 bytes |        1415 | 560.55 KiB    | 406 bytes | 1.02 MiB   |     53.44 |
 * | @@datadir/mysql/proc.MYD                        |        633 | 291.77 KiB | 472 bytes |         227 | 167.51 KiB    | 756 bytes | 459.28 KiB |     36.47 |
 * | @@datadir/ddl_log.log                           |         20 | 80.00 KiB  | 4.00 KiB  |          76 | 304.00 KiB    | 4.00 KiB  | 384.00 KiB |     79.17 |
 * | @@datadir/mem/statement_explain_data.frm        |         23 | 176.76 KiB | 7.69 KiB  |          53 | 118.91 KiB    | 2.24 KiB  | 295.67 KiB |     40.22 |
 * | @@datadir/mem/inventory_instance_attributes.frm |         29 | 121.47 KiB | 4.19 KiB  |          42 | 62.35 KiB     | 1.48 KiB  | 183.82 KiB |     33.92 |
 * | @@datadir/mem/rule_eval_result_vars.frm         |         15 | 61.27 KiB  | 4.08 KiB  |          28 | 62.63 KiB     | 2.24 KiB  | 123.89 KiB |     50.55 |
 * | @@datadir/subjects.frm                          |         16 | 49.39 KiB  | 3.09 KiB  |          31 | 52.69 KiB     | 1.70 KiB  | 102.08 KiB |     51.61 |
 * | @@datadir/mem/statement_data.frm                |          8 | 33.02 KiB  | 4.13 KiB  |          35 | 69.01 KiB     | 1.97 KiB  | 102.04 KiB |     67.64 |
 * +-------------------------------------------------+------------+------------+-----------+-------------+---------------+-----------+------------+-----------+
 */

DROP VIEW IF EXISTS top_io_by_file;

CREATE VIEW top_io_by_file AS
SELECT format_path(file_name) AS file, 
       count_read, 
       format_bytes(sum_number_of_bytes_read) AS total_read,
       format_bytes(IFNULL(sum_number_of_bytes_read / count_read, 0)) AS avg_read,
       count_write, 
       format_bytes(sum_number_of_bytes_write) AS total_written,
       format_bytes(IFNULL(sum_number_of_bytes_write / count_write, 0.00)) AS avg_write,
       format_bytes(sum_number_of_bytes_read + sum_number_of_bytes_write) AS total, 
       IFNULL(ROUND(100-((sum_number_of_bytes_read/(sum_number_of_bytes_read+sum_number_of_bytes_write))*100), 2), 0.00) AS write_pct 
  FROM performance_schema.file_summary_by_instance
 ORDER BY sum_number_of_bytes_read + sum_number_of_bytes_write DESC;

/*
 * View: top_io_by_thread
 *
 * Show the top IO consumers by thread, ordered by total latency
 *
 * Versions: 5.5+
 *
 * mysql> select * from top_io_by_thread;
 * +----------------------+------------+---------------+-------------+-------------+-------------+-----------+----------------+
 * | user                 | count_star | total_latency | min_latency | avg_latency | max_latency | thread_id | processlist_id |
 * +----------------------+------------+---------------+-------------+-------------+-------------+-----------+----------------+
 * | main                 |       1248 | 8.92 s        | 303.26 ns   | 34.29 ms    | 4.21 s      |         1 |           NULL |
 * | root@localhost:58511 |       3404 | 4.92 s        | 442.91 ns   | 910.57 µs   | 193.99 ms   |        47 |             26 |
 * | root@localhost:59479 |      22985 | 3.33 s        | 417.31 ns   | 135.05 µs   | 23.93 ms    |       121 |            100 |
 * | manager              |        651 | 40.68 ms      | 6.71 µs     | 62.46 µs    | 5.43 ms     |        20 |           NULL |
 * +----------------------+------------+---------------+-------------+-------------+-------------+-----------+----------------+
 *
 * (Example taken from 5.6.6)
 */

DROP VIEW IF EXISTS top_io_by_thread;

CREATE VIEW top_io_by_thread AS
SELECT IF(id IS NULL, 
             SUBSTRING_INDEX(name, '/', -1), 
             CONCAT(user, '@', host)
          ) user, 
       SUM(count_star) count_star,
       format_time(SUM(sum_timer_wait)) total_latency,
       format_time(MIN(min_timer_wait)) min_latency,
       format_time(AVG(avg_timer_wait)) avg_latency,
       format_time(MAX(max_timer_wait)) max_latency,
       thread_id,
       id AS processlist_id
  FROM performance_schema.events_waits_summary_by_thread_by_event_name 
  LEFT JOIN performance_schema.threads USING (thread_id) 
  LEFT JOIN information_schema.processlist ON processlist_id = id
 WHERE event_name LIKE 'wait/io/file/%'
   AND sum_timer_wait > 0
 GROUP BY thread_id
 ORDER BY SUM(sum_timer_wait) DESC;

/*
 * Procedure: only_enable()
 *
 * Only enable a certain form of wait event
 *
 * Parameters
 *   pattern: A LIKE pattern match of events to leave enabled
 *
 * Versions: 5.5+
 */

DROP PROCEDURE IF EXISTS only_enable;

DELIMITER $$

CREATE PROCEDURE only_enable(IN pattern VARCHAR(128))
BEGIN
    UPDATE performance_schema.setup_instruments
       SET enabled = IF(name LIKE pattern, 'YES', 'NO'),
           timed = IF(name LIKE pattern, 'YES', 'NO');
END$$

DELIMITER ;

/*
 * Procedure: currently_enabled()
 *
 * Show all enabled events / consumers
 *
 * Parameters
 *   show_instruments: Whether to show instrument configuration as well
 *
 * Versions: 5.5+
 *
 * mysql> call currently_enabled(TRUE);
 * +----------------------------+
 * | performance_schema_enabled |
 * +----------------------------+
 * |                          1 |
 * +----------------------------+
 * 1 row in set (0.00 sec)
 * 
 * +----------------------------+
 * | enabled_consumers          |
 * +----------------------------+
 * | file_summary_by_event_name |
 * | file_summary_by_instance   |
 * +----------------------------+
 * 2 rows in set (0.02 sec)
 * 
 * +---------------------------------+-------+
 * | enabled_instruments             | timed |
 * +---------------------------------+-------+
 * | wait/io/file/sql/map            | YES   |
 * ...
 * | wait/io/file/myisam/log         | YES   |
 * | wait/io/file/myisammrg/MRG      | YES   |
 * +---------------------------------+-------+
 * 39 rows in set (0.03 sec)
 */

DROP PROCEDURE IF EXISTS currently_enabled;

DELIMITER $$

CREATE PROCEDURE currently_enabled(show_instruments BOOLEAN)
BEGIN
    SELECT @@performance_schema AS performance_schema_enabled;

    SELECT name AS enabled_consumers
      FROM performance_schema.setup_consumers
     WHERE enabled = 'YES';

    IF (show_instruments) THEN
        SELECT name AS enabled_instruments,
               timed
          FROM performance_schema.setup_instruments
         WHERE enabled = 'YES';
    END IF;
END$$

DELIMITER ;

/*
 * Procedure: currently_disabled()
 *
 * Show all disabled events / consumers
 *
 * Parameters
 *   show_instruments: Whether to show instrument configuration as well
 *
 * Versions: 5.5+
 *
 * mysql> call currently_disabled(true);
 * +----------------------------+
 * | performance_schema_enabled |
 * +----------------------------+
 * |                          1 |
 * +----------------------------+
 * 1 row in set (0.00 sec)
 * 
 * +--------------------------------+
 * | disabled_consumers             |
 * +--------------------------------+
 * | events_stages_current          |
 * | events_stages_history          |
 * | events_stages_history_long     |
 * | events_statements_history      |
 * | events_statements_history_long |
 * | events_waits_current           |
 * | events_waits_history           |
 * | events_waits_history_long      |
 * +--------------------------------+
 * 8 rows in set (0.00 sec)
 * 
 * +---------------------------------------------------------------------------------------+-------+
 * | disabled_instruments                                                                  | timed |
 * +---------------------------------------------------------------------------------------+-------+
 * | wait/synch/mutex/sql/PAGE::lock                                                       | NO    |
 * | wait/synch/mutex/sql/TC_LOG_MMAP::LOCK_sync                                           | NO    |
 * | wait/synch/mutex/sql/TC_LOG_MMAP::LOCK_active                                         | NO    |
 * ...
 * | stage/sql/Waiting for event metadata lock                                             | NO    |
 * | stage/sql/Waiting for commit lock                                                     | NO    |
 * | wait/io/socket/sql/server_tcpip_socket                                                | NO    |
 * | wait/io/socket/sql/server_unix_socket                                                 | NO    |
 * | wait/io/socket/sql/client_connection                                                  | NO    |
 * +---------------------------------------------------------------------------------------+-------+
 * 302 rows in set (0.03 sec)
 * 
 * Query OK, 0 rows affected (1.19 sec)
 */

DROP PROCEDURE IF EXISTS currently_disabled;

DELIMITER $$

CREATE PROCEDURE currently_disabled(show_instruments BOOLEAN)
BEGIN
    SELECT @@performance_schema AS performance_schema_enabled;

    SELECT name AS disabled_consumers
      FROM performance_schema.setup_consumers
     WHERE enabled = 'NO';

    IF (show_instruments) THEN
        SELECT name AS disabled_instruments,
               timed
          FROM performance_schema.setup_instruments
         WHERE enabled = 'NO';
    END IF;
END$$

DELIMITER ;
