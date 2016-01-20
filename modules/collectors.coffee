Q = require 'q'
_ = require 'underscore'

load = require "../lib/load"
modules = require("config").modules
useWhitelistedKeys = require("config").useWhitelistedKeys
whitelistedkeys = ''

module.exports = ({app, logger, config}, next) ->
  collectorHandler = (collectors) ->
    arrOfVals = []
    return (req, res) ->
      if useWhitelistedKeys
        for fields of req.body
          if (arrOfVals.indexOf( fields ) == -1)
            arrOfVals.push( fields )
        if arrayEqual(arrOfVals, whitelistedkeys)
          res.send(204, '')
        else
          res.send(406, '')
      else
        res.send(204, '')

      for coll in collectors
        coll(req.body, {req, res})

  logger.log "Loading collectors: #{ modules.collectors.join(', ') }"
  whitelistedkeys = "#{modules.whitelistedKeys}".split(',')

  collectors = {}
  collPromises = []
  _.map modules.collectors, (name) ->
    promise = load name, {logger, config, app}
    promise.then (ret) ->
      logger.log "Collector #{ name } ready"
      collectors[name] = ret

    collPromises.push promise

  Q.all(collPromises).done ->
    handlers = {}
    for name, collector of collectors
      for path, handler of collector
        if not handlers[path]?
          handlers[path] = [handler]
        else
          handlers[path].push handler

    collector = {}
    for path, hls of handlers
      collector[path] = collectorHandler(hls)

    next collector

  arrayEqual = (a, b) ->
    a.length is b.length and a.every (elem, i) -> elem is b[i]