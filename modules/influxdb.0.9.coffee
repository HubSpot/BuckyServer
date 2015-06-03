_ = require('underscore')

InfluxDB = require '../lib/influxdb.0.9'

module.exports = ({config, app, logger}, next) ->
  influxdb = new InfluxDB config, logger

  next
    send: (data) ->
      influxdb.write data
