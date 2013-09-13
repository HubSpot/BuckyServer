Q = require 'q'
_ = require 'underscore'

load = require "../lib/load"
modules = require("config").Modules

module.exports = ({app, logger, config}, next) ->
  collectorHandler = (collectors) ->
    return (req, res) ->
      res.send(204, '')

      for coll in collectors
        coll(req.body, {req, res})

  logger.log "Loading collectors: #{ modules.Collectors }"

  collectors = {}
  collPromises = []
  _.map modules.Collectors, (name) ->
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
