http = require 'http'

# Create and bind a new server to a host and port.
# options are:
#   port
#   host
#   requestHandler
#
# success handler is the second parameter:
#   onSuccess
bindServer = (opts, onSuccess) ->
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
    if typeof onSuccess isnt 'function'
        onSuccess = ->

    server = http.createServer opts.requestHandler

    server.on 'error', (err) ->
        if err.code is 'EADDRINUSE'
            process.stderr.write 'bind server error:\n'
            process.stderr.write 'server address already in use: '
            process.stderr.write "#{ opts.host }:#{ opts.port }\n"
            process.stderr.write 'Try a different host name or port number.\n'

    # Invoke server.listen() on the next tick to give the caller a chance to
    # attach event listeners
    process.nextTick ->
        server.listen opts.port, opts.host, ->
            onSuccess server

    return server

exports.bindServer = bindServer

class Client
    host: 'localhost'
    port: 8080

    constructor: (opts) ->
        if typeof opts is 'string'
            @host = opts
            if @host isnt 'localhost' and @host isnt '127.0.0.1'
                @port = 80
        return

    get: (path, headers) ->
        path or= '/'
        @send {method: 'GET', path: path, headers: headers}

    send: (opts) ->
        opts = @extend opts
        rv = null

        request = http.get opts, (res) ->
            buff = ''

            res.setEncoding 'utf8'

            res.on 'data', (chunk) ->
                buff += chunk

            res.once 'end', ->
                if rv then return
                res.body = buff
                rv =
                    error: null
                    response: res

        request.once 'error', (err) ->
            if rv then return
            request.abort()
            rv =
                error: err
                response: null

        request.end()

        check = ->
            return rv

        return {check: check, request: request}

    extend: (opts) ->
        rv =
            host: @host
            port: @port
            method: @method
            path: @path
            headers: @headers

        opts or= {}
        if opts.host and typeof opts.host is 'string'
            rv.host = opts.host
        if typeof opts.port is 'number'
            rv.port = opts.port
        if opts.method and typeof opts.method is 'string'
            rv.method = opts.method
        if opts.path and typeof opts.path is 'string'
            rv.path = opts.path
        if opts.headers and typeof opts.headers is 'object'
            rv.headers = opts.headers

        return rv

exports.Client = Client
