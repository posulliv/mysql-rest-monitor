# Description:
#   Get information from a MySQL monitoring REST service.
#
# Configuration:
#   HUBOT_MYSQL_REST_URL
#
# Commands:
#   hubot mysql bad_queries server_name
#   hubot mysql queries_tmp_tables server_name
#   hubot mysql table_stats server_name schema_name table_name
#   hubot mysql index_stats server_name schema_name table_name
#   hubot mysql lock_user server_name username
#   hubot mysql unlock_user server_name username
#   hubot mysql trx_summary server_name
#   hubot mysql active_trx server_name
#   hubot mysql blocked_trx server_name
#   hubot mysql kill_idle_trx server_name idle_time
#   hubot mysql kill_blocking_trx server_name wait_time
#
# Author:
#   posulliv

URL  = require "url"
url  = URL.parse(process.env.HUBOT_MYSQL_REST_URL)
HTTP = require(url.protocol.replace(/:$/, ""))

defaultOptions = () ->
  template =
    host: url.hostname
    port: url.port || 80
    path: url.pathname

get = (path, params, cb) ->
  options = defaultOptions()
  options.path += path
  console.log(options)
  req = HTTP.request options, (res) ->
    body = ""
    res.setEncoding("utf8")
    res.on "data", (chunk) ->
      body += chunk
    res.on "end", () ->
      cb null, res.statusCode, body
  req.on "error", (e) ->
    console.log(e)
    cb e, 500, "Client Error"
  req.end()

put = (path, params, cb) ->
  post path, params, cb, 'PUT'

post = (path, params, cb, method='POST') ->
  bodyParams     = JSON.stringify params

  options        = defaultOptions()
  options.method = method
  options.headers['Content-Length'] = bodyParams.length

  req = HTTP.request options, (res) ->
    body = ""
    res.setEncoding("utf8")
    res.on "data", (chunk) ->
      body += chunk
    res.on "end", () ->
      cb null, res.statusCode, body
  req.on "error", (e) ->
    console.log(e)
    cb e, 500, "Client Error"
  req.end(bodyParams)

module.exports = (robot) ->

  robot.respond /mysql bad_queries ([-_\.0-9a-zA-Z]+)/i, (msg) ->
    db = msg.match[1]
    get "#{db}/bad_queries", {}, (err, statusCode, body) ->
      if statusCode == 200
        msg.send body
      else
        msg.send "the god damn plane has crashed into the building"

  robot.respond /mysql queries_tmp_tables ([-_\.0-9a-zA-Z]+)/i, (msg) ->
    db = msg.match[1]
    get "#{db}/queries_tmp_tables", {}, (err, statusCode, body) ->
      if statusCode == 200
        msg.send body
      else
        msg.send "the god damn plane has crashed into the building"

  robot.respond /mysql table_stats ([-_\.0-9a-zA-Z]+) ([-_\.0-9a-zA-Z]+) ([-_\.0-9a-zA-Z]+)/i, (msg) ->
    db = msg.match[1]
    schema = msg.match[2]
    table = msg.match[3]
    get "#{db}/table_stats/#{schema}/#{table}", {}, (err, statusCode, body) ->
      if statusCode == 200
        msg.send body
      else
        msg.send "the god damn plane has crashed into the building"

  robot.respond /mysql index_stats ([-_\.0-9a-zA-Z]+) ([-_\.0-9a-zA-Z]+) ([-_\.0-9a-zA-Z]+)/i, (msg) ->
    db = msg.match[1]
    schema = msg.match[2]
    table = msg.match[3]
    get "#{db}/table_stats/#{schema}/#{table}", {}, (err, statusCode, body) ->
      if statusCode == 200
        msg.send body
      else
        msg.send "the god damn plane has crashed into the building"

  robot.respond /mysql lock_user ([-_\.0-9a-zA-Z]+) ([-_\.0-9a-zA-Z]+)/i, (msg) ->
    db = msg.match[1]
    user = msg.match[2]
    put "#{db}/#{user}/lock", {}, (err, statusCode, body) ->
      if statusCode == 200
        msg.send body
      else
        msg.send "stay out of malibu lebowski"

  robot.respond /mysql unlock_user ([-_\.0-9a-zA-Z]+) ([-_\.0-9a-zA-Z]+)/i, (msg) ->
    db = msg.match[1]
    user = msg.match[2]
    put "#{db}/#{user}/unlock", {}, (err, statusCode, body) ->
      if statusCode == 200
        msg.send body
      else
        msg.send "stay out of malibu lebowski"

  robot.respond /mysql trx_summary ([-_\.0-9a-zA-Z]+)/i, (msg) ->
    db = msg.match[1]
    get "#{db}/trx_summary", {}, (err, statusCode, body) ->
      if statusCode == 200
        msg.send body
      else
        msg.send "the god damn plane has crashed into the building"

  robot.respond /mysql active_trx ([-_\.0-9a-zA-Z]+)/i, (msg) ->
    db = msg.match[1]
    get "#{db}/active_trx", {}, (err, statusCode, body) ->
      if statusCode == 200
        msg.send body
      else
        msg.send "the god damn plane has crashed into the building"

  robot.respond /mysql blocked_trx ([-_\.0-9a-zA-Z]+)/i, (msg) ->
    db = msg.match[1]
    get "#{db}/blocked_trx", {}, (err, statusCode, body) ->
      if statusCode == 200
        msg.send body
      else
        msg.send "the god damn plane has crashed into the building"

  robot.respond /mysql kill_idle_trx ([-_\.0-9a-zA-Z]+) ([-_\.0-9a-zA-Z]+)/i, (msg) ->
    db = msg.match[1]
    idle_time = msg.match[2]
    put "#{db}/kill_idle_trx/#{idle_time}", {}, (err, statusCode, body) ->
      if statusCode == 200
        msg.send body
      else
        msg.send "stay out of malibu lebowski"

  robot.respond /mysql kill_blocking_trx ([-_\.0-9a-zA-Z]+) ([-_\.0-9a-zA-Z]+)/i, (msg) ->
    db = msg.match[1]
    blocking_time = msg.match[2]
    put "#{db}/kill_blocking_trx/#{blocking_time}", {}, (err, statusCode, body) ->
      if statusCode == 200
        msg.send body
      else
        msg.send "stay out of malibu lebowski"
