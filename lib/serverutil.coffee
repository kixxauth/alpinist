events = require 'events'
http   = require 'http'

class Manager extends events.EventEmitter
    defaults:
        port: 8080
        address: '127.0.0.1'

    # Create and bind a new server to a host and port.
    # options are:
    #   port
    #   host
    #   requestHandler
    #
    # success handler is the second parameter:
    #   onSuccess
    applyServer: (opts, onSuccess) ->
        opts or= {}
        if typeof opts.port isnt 'number'
            opts.port = @defaults.port
        if typeof opts.host isnt 'string'
            opts.host = @defaults.address
        if typeof opts.handler isnt 'function'
            opts.handler = (req, res) ->
                res.end()
        if typeof onSuccess isnt 'function'
            onSuccess = ->

        server = http.createServer opts.handler

        server.on 'error', (err) =>
            if err.code is 'EADDRINUSE'
                msg = "server address already in use:
                #{ opts.host }:#{ opts.port }
                Try a different host name or port number."
                @emit 'error', new Error(msg)


        # Invoke server.listen() on the next tick to give the caller a chance to
        # attach event listeners
        process.nextTick ->
            server.listen opts.port, opts.host, ->
                onSuccess server

        return server


exports.Manager = Manager
