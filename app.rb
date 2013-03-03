require 'sinatra'
require 'sequel'
require 'json'
require 'logger'
require 'pp'

require './servers'
require './queries'

DB = Sequel.connect($default,
                    :servers => $slaves,
                    :default => $masters)
DB.sql_log_level = :debug
DB.logger = Logger.new($stdout)

class App < Sinatra::Base

  helpers do
    def exec_query(sql, host, *args)
      dataset = DB[sql, *args].server(host.to_sym)
      res = []
      dataset.map { |r|
        res << r
      }
      res
    end
  end

  get "/:db/bad_queries" do
    exec_query(Queries::BAD_QUERIES, params[:db]).to_json
  end

  get "/:db/queries_tmp_tables" do
    exec_query(Queries::QUERIES_TMP_TABLES, params[:db]).to_json
  end

  get "/:db/table_stats/:schema_name/:table_name" do
    exec_query(Queries::TABLE_STATS, params[:db], params[:schema_name], params[:table_name]).to_json
  end

  get "/:db/index_stats/:schema_name/:table_name" do
    exec_query(Queries::INDEX_STATS, params[:db], params[:schema_name], params[:table_name]).to_json
  end

  get "/:db/schema_size/:schema_name" do
    exec_query(Queries::SCHEMA_SIZE, params[:db], params[:schema_name]).to_json
  end

  put "/:db/:username/lock" do
    exec_query(Queries::LOCK_USER, params[:db], params[:username])
    { "username" => params[:username], "status" => "locked" }.to_json
  end

  put "/:db/:username/unlock" do
    exec_query(Queries::UNLOCK_USER, params[:db], params[:username])
    { "username" => params[:username], "status" => "unlocked" }.to_json
  end

  get "/:db/trx_summary" do
    exec_query(Queries::TRX_SUMMARY, params[:db]).to_json
  end

  get "/:db/active_trx" do
    exec_query(Queries::ACTIVE_TRX, params[:db]).to_json
  end

  get "/:db/blocked_trx" do
    exec_query(Queries::BLOCKED_TRX, params[:db]).to_json
  end

  put "/:db/kill_idle_trx/:idle_time" do
    exec_query(Queries::KILL_IDLE_TRX, params[:db], params[:idle_time])
    { "status" => "ok" }.to_json
  end

  put "/:db/kill_blocking_trx/:idle_time" do
    exec_query(Queries::KILL_BLOCKING_TRX, params[:db], params[:idle_time])
    { "status" => "ok" }.to_json
  end

end
