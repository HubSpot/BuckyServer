Q = require 'q'
_ = require 'underscore'

load = require "../lib/load"
modules = require("config").modules

module.exports = ({app, logger, config}, next) ->
  collectorHandler = (collectors) ->
    return (req, res) ->
      res.send(204, '')

      # filter internal requests
      isInternalRequest = true if req.ip.indexOf config.get('server.internalIpFragment').get() > -1

      if isInternalRequest
        logger.log "#! > Skipping collectors for request from internal ip:", req.ip
        return true

      for coll in collectors
        coll(req.body, {req, res})

  logger.log "Loading collectors: #{ modules.collectors.join(', ') }"

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
