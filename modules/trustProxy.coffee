module.exports = ({app}, next) ->
  # This tells express to trust the proxy headers it might get from our lbs
  app.enable('trust proxy')

  next()
