request = require('request')
dgram = require('dgram')

class Client
  constructor: (@config={}, @logger) ->
    do @init

  init: ->
    useUDP = @config.get('influxdb.use_udp').get() ? false

    @send = if useUDP then @sendUDP() else @sendHTTP()

  write: (metrics) ->
    @send @metricsStringify metrics

  sendHTTP: ->
    version = @config.get('influxdb.version').get() ? '0.9'
    host = @config.get('influxdb.host').get() ? 'localhost'
    port = @config.get('influxdb.port').get() ? 8086
    database = @config.get('influxdb.database').get() ? 'bucky'
    username = @config.get('influxdb.username').get() ? 'root'
    password = @config.get('influxdb.password').get() ? 'root'
    use_json = @config.get('influxdb.use_json').get() ? false
    logger = @logger
    if version == '0.8'
      endpoint = 'http://' + host + ':' + port + '/db/' + database + '/series'
    else
      endpoint = 'http://' + host + ':' + port + '/write'
      if not use_json
          endpoint += '?db=' + database + '&rp=' + (@config.get('influxdb.retentionPolicy').get() ? "default")
    client = request.defaults
      method: 'POST'
      url: endpoint
      qs:
        u: username
        p: password

    (metricsJson) ->
      client form: metricsJson, (error, response, body) ->
        logger.log error if error

  sendUDP: ->
    host = @config.get('influxdb.host').get() ? 'localhost'
    port = @config.get('influxdb.port').get() ? 4444
    client = dgram.createSocket 'udp4'

    (metricsJson) ->
      message = new Buffer metricsJson

      client.send message, 0, message.length, port, host

  metricsStringify: (metrics) ->
    version = @config.get('influxdb.version').get() ? '0.9'
    use_json = @config.get('influxdb.use_json').get() ? false
    if version == '0.8'
      data = []
    else if use_json
      data =
        database: @config.get('influxdb.database').get() ? 'bucky'
        retentionPolicy: @config.get('influxdb.retentionPolicy').get() ? "default"
        time: new Date().toISOString()
        points: []
    else
      data = []
      hrTime = process.hrtime()
      timestamp = new Date().getTime() * 1e6
    for key, desc of metrics
      [val, unit, sample] = @parseRow key,desc

      if not val?
          continue

      if version == '0.8'
        data.push
          name: key,
          columns: ['value'],
          points: [[parseFloat val]]
      else if use_json is true
        data.points.push
          measurement: key
          fields:
            value: parseFloat val
            unit: unit
            sample: sample
      else
        str = (@escape key, false) + ' value=' + (parseFloat val)
        if unit?
            str += ',unit="' + unit + '"'
        if sample?
            str += ',sample="' + sample + '"'
        str += ' ' + timestamp
        data.push str
    if version == '0.8' or use_json is true
      #@logger.log(JSON.stringify(data, null, 2))
      JSON.stringify data
    else
      @logger.log(data.join("\n"))
      data.join("\n")

  parseRow: (key, row) ->
    re = /([0-9\.]+)\|([a-z]+)(?:@([0-9\.]+))?/

    groups = re.exec(row)

    unless groups
      @logger.log "Unparsable row: #{ row } key: #{ key }"
      return []

    groups.slice(1, 4)

  escape: (value, escapeEqualSign = true) ->
    escaped = value.replace(/(\s+)/, '\\ ').replace(/,/, '\\,')
    if escapeEqualSign
        escaped = escaped.replace(/\=/, '\\=')

    escaped

module.exports = Client
