module.exports = ({app, logger, config}, next) ->

  next
    send: (req, res, _next) ->
      # res.send(401, "Unauthorized")
      _next()
