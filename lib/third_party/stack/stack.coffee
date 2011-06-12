stack = (funcs...) ->
    error = exports.errorHandler
    handler = error
    self = {}

    compose = (layer) ->
        child = handler
        handler = (req, res) ->
            layer.call self, req, res, (err) ->
                if err then return error(req, res, err)
                child(req, res)
                return
            return

    funcs.reverse().forEach(compose)
    return handler

exports.errorHandler = (req, res, err) ->
    if err
        res.writeHead(500, {'Content-Type': 'text/plain'})
        res.end(err.message)
        return

    res.writeHead(404, {'Content-Type': 'text/plain'})
    res.end('Not Found\n')
    return

exports.stack = stack
