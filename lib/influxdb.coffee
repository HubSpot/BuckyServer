request = require 'request'
dgram = require 'dgram'

class Client
  constructor: (@config={}, @logger) ->
    do @init

  init: ->
    useUDP = @config.get('influxdb.use_udp').get() ? false
    version = @config.get('influxdb.version').get() ? '0.9'
    throw new Error "Invalid InfluxDB Version" if version not in ['0.8', '0.9']
    
    @send = if useUDP then @sendUDP() else @sendHTTP()

  write: (metrics) ->
    @send @formatMetrics metrics

  sendHTTP: ->
    version = @config.get('influxdb.version').get() ? '0.9'
    host = @config.get('influxdb.host').get() ? 'localhost'
    port = @config.get('influxdb.port').get() ? 8086
    database = @config.get('influxdb.database').get() ? 'bucky'
    username = @config.get('influxdb.username').get() ? 'root'
    password = @config.get('influxdb.password').get() ? 'root'
    retentionPolicy = @config.get('influxdb.retentionPolicy').get() ? 'default'
    logger = @logger

    clientConfig =
      method: 'POST'
      qs:
        u: username
        p: password

    if version == '0.9'
      clientConfig.url = 'http://' + host + ':' + port + '/write'
      clientConfig.qs.db = database
      clientConfig.qs.rp = retentionPolicy
    else
      clientConfig.url = 'http://' + host + ':' + port + '/db/' + database + '/series'

    client = request.defaults clientConfig

    (formatMetrics) ->
      if version == '0.9'
        metrics = formatMetrics.join '\n'
        # uncomment to see data sent to DB
        # logger.log 'db: ' + database + '\n' + metrics
        client body: metrics, (error, response, body) ->
          logger.log 'Warning:' if body && body.length > 0
          logger.log '\tresponse:\n', body if body && body.length > 0
          logger.log error if error
      else
        metrics = JSON.stringify formatMetrics
        # logger.log 'db: ' + database + '\n' + metrics
        client form: metrics, (error, response, body) ->
          logger.log 'Warning:' if body && body.length > 0
          logger.log '\tresponse:\n', body if body && body.length > 0
          logger.log error if error

  sendUDP: ->
    version = @config.get('influxdb.version').get() ? '0.9'
    host = @config.get('influxdb.host').get() ? 'localhost'
    port = @config.get('influxdb.port').get() ? 4444
    client = dgram.createSocket 'udp4'

    (formatMetrics) ->
      if version == '0.9'
        formatMetrics.forEach (metric) ->
          message = new Buffer metric
          client.send message, 0, message.length, port, host
      else
        message = new Buffer JSON.stringify formatMetrics
        client.send message, 0, message.length, port, host

  formatMetrics: (metrics) ->
    version = @config.get('influxdb.version').get() ? '0.9'
    data = []

    for key, desc of metrics
      [val, unit, sample] = @parseRow desc

      if version == '0.9'
        fields = key.replace(/\\? /g, '\\ ')
        fields += ' value=' + parseFloat val
        fields += ',unit="' + unit.replace(/"/g, '\\"') + '"' if unit
        fields += ',sample=' + sample if sample
      else
        fields =
          name: key,
          columns: ['value'],
          points: [[parseFloat val]]
      data.push fields

    data

  parseRow: (row) ->
    re = /([0-9\.]+)\|([a-z]+)(?:@([0-9\.]+))?/

    groups = re.exec(row)

    unless groups
      @logger.log 'Unparsable row: #{ row }'
      return

    groups.slice(1, 4)

module.exports = Client
