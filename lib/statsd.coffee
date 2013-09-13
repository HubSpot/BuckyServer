Lynx = require('lynx')

class Client
  constructor: (@config={}) ->
    do @init

  init: ->
    host = @config.get('statsd.host').get() ? 'localhost'
    port = @config.get('statsd.port').get() ? 8125

    @lynx = new Lynx(host, port)

  write: (metrics) ->
    @lynx.send metrics

module.exports = Client
