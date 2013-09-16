#!/usr/bin/env coffee

Q = require 'q'
_ = require 'underscore'
config = require 'config'

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

loadApp = (logger, config) ->
  express = require('express')
  app = express()

  app.use express.bodyParser()

  APP_ROOT = process.env.APP_ROOT ? config.server?.appRoot ? ''

  moduleGroups = {}
  loadModuleGroup = (group) ->
    moduleGroups[group] = {}

    if MODULES[group]
      _.map MODULES[group], (name) ->
        logger.log "Loading #{ group } Module", name

        try
          promise = load name, {logger, config, app}
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
        route = "#{ APP_ROOT }/#{ path }"
        if not routes[route]?
          routes[route] = [handler]
        else
          routes[route].push handler

    for path, handlers of routes
      # Bind all request modules as middleware and install the collectors
      app.post.apply app, _.union(path, handlers)

      app.options path, (req, res) ->
        # CORS support
        
        res.setHeader 'Access-Control-Allow-Origin', '*'
        res.setHeader 'Access-Control-Allow-Methods', 'POST'
        res.setHeader 'Access-Control-Max-Age', '604800'
        res.setHeader 'Access-Control-Allow-Credentials', 'true'

        res.send 200, ''

    app.get "#{ APP_ROOT }/warmup", (req, res) ->
      res.send('warmed up')

    port = process.env.PORT ? config.server?.port ? 5000
    app.listen(port)

    logger.log('Server listening on port %d in %s mode', port, app.settings.env)

Q.when(loadLogger()).then (logger) ->

  logger.log "Loading Config"
  Q.when(loadConfig(logger)).then (config) ->

    logger.log "Loading App"
    loadApp(logger, config)
