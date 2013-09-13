SentryHandler = require('unhapi/sentry')

module.exports = ({logger, config}, next) ->
  logger.addHandler SentryHandler, {sentry: {dsn: config.get('sentry.dsn').get()}}

  next()
