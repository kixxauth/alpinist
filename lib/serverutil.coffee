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

class RewriteRule
    regex: null
    path: null
    host: null
    port: null

    constructor: (spec) ->
        spec or= {}

        spec.regex = typeof spec.regex is 'string' and spec.regex or '^/'
        @regex = new RegExp(spec.regex, 'i')

        spec.path = typeof spec.path is 'string' and spec.path or '/'
        @path = spec.path

        spec.host = typeof spec.host is 'string' and spec.host or '127.0.0.1'
        @host = spec.host

        spec.port = typeof spec.port is 'number' and spec.port or 0
        @port = spec.port

exports.RewriteRule = RewriteRule


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

class HttpProxy extends events.EventEmitter
    proxyRequest: (request, response, options) ->
        proxy = @
        host = options.host
        port = options.port

        proxyOpts =
            host: host
            port: port
            method: request.method
            path: request.url
            headers: request.headers

        reverseProxy = http.request proxyOpts, (proxyResponse) ->
            response.writeHead(proxyResponse.statusCode, proxyResponse.headers)
            proxyResponse.pipe(response)
            return

        reverseProxy.once 'error', (err) ->
            response.writeHead(500)
            response.end()
            proxy.emit('error', err)
            return

        request.pipe(reverseProxy)
        return

exports.HttpProxy = HttpProxy
