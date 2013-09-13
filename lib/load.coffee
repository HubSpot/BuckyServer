Q = require 'q'
_ = require 'underscore'

module.exports = (name, args) ->
  deferred = Q.defer()

  module = require name
  module args, _.bind(deferred.resolve, deferred)

  deferred.promise
