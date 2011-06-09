events = require 'events'
http   = require 'http'

write404 = (res, message) ->
    res.writeHead 404, {'content-type': 'text/html'}
    body = "\n"
    if message
        body = "<html><body><p>#{ message }</p></body></html>\n"
    res.end body
    return

exports.write404 = write404


write500 = (res, err) ->
    res.writeHead 500, {'content-type': 'text/plain'}
    body = '\n'
    if err and typeof err is 'object'
        body = "A server error has been encountered: 
        #{ err.name }: #{ err.message }\n"
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


# @param {String} path An URL path string like /foo/bar.html
# @param {Array} rules A list of RewriteRule instance objects
#
# @returns {Object} A object with properties .path, .host, and .port
#
# An instance of RewriteRule my include .regex, .path, .host, and .port
# definitions.
#
# If no rules are passed, the path is simply returned as is.
#
# If no rules are matched using the .regex property the path is simply returned
# as is.
#
# The first .regex match is used and the rest are ignored.
#
# If no .path is given in a matched RewriteRule instance, the .path is simply returned
# as is.
#
# The returned .path will be the .path of the RewriteRule if a match is made
# using the .regex property of the rule.
#
# If there is a .host property on a matched RewriteRule, the returned object
# will inherit the .host property.
#
# If there is a .port property on a matched RewriteRule, the returned object
# will inherit the .port property.
#
# If there is a subgroup in the .regex of the RewriteRule and replacement
# characters in the .path of the rewrite rule, then replacement will take
# effect in the returned .path. Example:
#
#       rules = [{regex: /^\/foopath\/([a-z]*)\/uid\/(.*)/, path: '/barpath/$1/id/$2'}]
#       newURL = serverutil.rewriteURL('/foopath/val/uid/123qwe', rules)
#       expect(newURL.path).toBe '/barpath/val/id/123qwe'
#
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
