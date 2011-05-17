events = require 'events'
http   = require 'http'

write404 = (res, message) ->
    res.writeHead 404, {'content-type': 'text/html'}
    body = "<html><body><p>#{ message }</p></body></html>"
    res.end body
    return

exports.write404 = write404


write500 = (res, err) ->
    res.writeHead 500, {'content-type': 'text/plain'}
    body = "A server error has been intercepted by proxy: 
    #{ err.name }: #{ err.message }"
    res.end body
    return

exports.write500 = write500


rewriteURL = (path, rules) ->
    rv =
        path: path
        host: null
        port: null

    if not Array.isArray(rules)
        rules = []

    if not rules.length then return rv

    for rule in rules
        match = rule.regex.exec path
        if match
            if typeof rule.path is 'string'
                rv.path = rule.path
                if match.length > 1
                    for i in [1..match.length]
                        rv.path = rv.path.replace "$#{i}", match[i]
            if typeof rule.host is 'string'
                rv.host = rule.host
            if typeof rule.port is 'number'
                rv.port = rule.port
            return rv

    return rv

exports.rewriteURL = rewriteURL


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
