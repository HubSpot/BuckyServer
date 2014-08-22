request = require('request')

class Client
  constructor: (@config={}, @logger) ->
    do @init

  init: ->
    host = @config.get('influxdb.host').get() ? 'localhost'
    port = @config.get('influxdb.port').get() ? 8086
    database = @config.get('influxdb.database').get() ? 'bucky'
    username = @config.get('influxdb.username').get() ? 'root'
    password = @config.get('influxdb.password').get() ? 'root'

    @request = request.defaults
      method: 'POST'
      url: 'http://' + host + ':' + port + '/db/' + database + '/series'
      qs:
        u: username
        p: password

  write: (metrics) ->
    data = []
    for key, desc of metrics
      [val, unit, sample] = @parseRow desc

      data.push
        name: key,
        columns: ['value'],
        points: [[val]]

    data = JSON.stringify data

    logger = @logger
    @request form: data, (error, response, body) ->
      logger.log error

  parseRow: (row) ->
    re = /([0-9\.]+)\|([a-z]+)(?:@([0-9\.]+))?/

    groups = re.exec(row)

    unless groups
      @logger.log "Unparsable row: #{ row }"
      return

    groups.slice(1, 4)

module.exports = Client
