#!/usr/bin/env coffee

Q = require 'q'
_ = require 'underscore'
express = require 'express'
config = require 'config'
cluster = require 'cluster'

configWrapper = require './lib/configWrapper'
load = require './lib/load'

MODULES = config.modules
loadLogger = ->
  if MODULES.logger
    load(MODULES.logger, {config})
  else
    console

# We always have the base config, but the
# app can optionally swap it out for something else.
loadConfig = (logger) ->
  if MODULES.config
    load(MODULES.config, {config, logger})
  else
    configWrapper(config)

setCORSHeaders = (req, res, next) ->
  res.setHeader 'Access-Control-Allow-Origin', '*'
  res.setHeader 'Access-Control-Allow-Methods', 'POST'
  res.setHeader 'Access-Control-Max-Age', '604800'
  res.setHeader 'Access-Control-Allow-Credentials', 'true'

  next()

parser = (req, res, next) ->
  buf = ''
  req.body = {}

  req.setEncoding 'utf8'

  req.on 'data', (chunk) ->
    buf += chunk

  req.on 'end', ->
    metrics = buf.split('\n')

    for metric in metrics
      [name, value] = metric.split(':')

      if name and value
        req.body[name] = value

    next()

loadApp = (logger, loadedConfig) ->
  app = express()

  APP_ROOT = process.env.APP_ROOT ? loadedConfig.get('server.appRoot').get() ? ''

  moduleGroups = {}
  loadModuleGroup = (group) ->
    moduleGroups[group] = {}

    if MODULES[group]
      _.map MODULES[group], (name) ->
        logger.log "Loading #{ group } Module", name

        try
          promise = load name, {logger, app, config: loadedConfig}
        catch e
          console.log "Error loading module", e?.stack

        promise.then (ret) ->
          logger.log name, "Ready"
          moduleGroups[group][name] = ret

        promise
    else
      []

  appPromises = loadModuleGroup 'app'

  Q.all(appPromises).then ->
    logger.log "Binding Routes at %s", (APP_ROOT or '/')

    # Allow modules to bind to any number of endpoints
    # Most should simply bind to "send"
    routes = {}
    for name, _routes of moduleGroups.app
      continue if not _routes?

      if _.isFunction _routes
        _routes = {send: _routes}

      for path, handler of _routes
        route = "#{ APP_ROOT }/v1/#{ path }"
        if not routes[route]?
          routes[route] = [handler]
        else
          routes[route].push handler

    for path, handlers of routes
      # Bind all request modules as middleware and install the collectors
      app.post path, parser, setCORSHeaders, handlers...

      app.options path, setCORSHeaders, (req, res) ->
        res.send 200, ''

    app.get "#{ APP_ROOT }/v1/health-check", (req, res) ->
      res.send('OK\n')

    port = process.env.PORT ? loadedConfig.get('server.port').get() ? 5000
    port = (port + cluster.worker.id - 1) if process.env.CLUSTER && cluster.isWorker
    app.listen(port)

    logger.log('Server listening on port %d in %s mode', port, app.settings.env)

Q.when(loadLogger()).then (logger) ->

  logger.log "Loading Config"
  Q.when(loadConfig(logger)).then (loadedConfig) ->

    logger.log "Loading App"
    loadApp(logger, loadedConfig)
