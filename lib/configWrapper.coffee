# Our config format is designed to work with config types which can be changed
# on the fly.  This wraps simple objects to work with it.
wrap = (obj) ->
  {
    get: (key) ->
      {
        get: ->
          cur = obj
          for part in key.split('.')
            cur = cur?[part]
          cur

        on: ->
      }
  }

module.exports = wrap
