_ = require('underscore')

OpenTSDB = require '../lib/opentsdb'

module.exports = ({app, config, logger}, next) ->
  openTSDB = new OpenTSDB config, logger

  next
    send: (data) ->
      openTSDB.write data
