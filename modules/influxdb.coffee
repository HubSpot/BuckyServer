_ = require('underscore')

InfluxDB = require '../lib/influxdb'

module.exports = ({config, app, logger}, next) ->
  influxdb = new InfluxDB config, logger

  next
    send: (data) ->
      influxdb.write data
