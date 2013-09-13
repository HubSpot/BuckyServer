_ = require('underscore')

Statsd = require '../lib/statsd'

module.exports = ({config, app, logger}, next) ->
  statsd = new Statsd config, logger

  next
    send: (data) ->
      statsd.write data
