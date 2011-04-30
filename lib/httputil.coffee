http = require 'http'

# Create and bind a new server to a host and port.
# options are:
#   port
#   host
#   requestHandler
#   onSuccess
bindServer = (opts) ->
    defaultPort = 8080
    defaultHost = '127.0.0.1'
    opts or= {}
    if typeof opts.port isnt 'number'
        opts.port = defaultPort
    if typeof opts.host isnt 'string'
        opts.host = defaultHost
    if typeof opts.requestHandler isnt 'function'
        opts.requestHandler = (req, res) ->
            res.end()
    if typeof opts.onSuccess isnt 'function'
        opts.onSuccess = ->

    server = http.createServer opts.requestHandler

    server.on 'error', (err) ->
        if err.code is 'EADDRINUSE'
            process.stderr.write 'bind server error:\n'
            process.stderr.write 'server address already in use: '
            process.stderr.write "#{ opts.host }:#{ opts.port }\n"
            process.stderr.write 'Try a different host name or port number.\n'

    # Do this to give the caller a chance to attach event listeners
    process.nextTick ->
        server.listen opts.port, opts.host, opts.onSuccess

    return server

exports.bindServer = bindServer
