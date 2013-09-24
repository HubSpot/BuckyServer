Nopents = require('nopents')

class Client
  constructor: (@config, @logger) ->
    do @init

  init: ->
    @nopents = new Nopents {
      host: @config.get('opentsdb.host').get()
      port: @config.get('opentsdb.port').get()
    }

  write: (metrics) ->
    data = []
    for key, desc of metrics
      [val, unit, sample] = @parseRow desc

      data.push {key: key, val: val, tags: {source: 'bucky'}}

    @nopents.send data

  parseRow: (row) ->
    re = /([0-9\.]+)\|([a-z]+)(?:@([0-9\.]+))?/

    groups = re.exec(row)

    unless groups
      @logger.log "Unparsable row: #{ row }"
      return

    groups.slice(1, 4)

module.exports = Client
