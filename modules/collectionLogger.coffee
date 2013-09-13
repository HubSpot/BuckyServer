_ = require('underscore')

module.exports = ({logger, app}, next) ->

  next
    send: (data, {req}) ->
      logger.log "Collecting", _.keys(data).join(', '), 'for', req.ip
