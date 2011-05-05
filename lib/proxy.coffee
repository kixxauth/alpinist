events = require 'events'
util   = require 'util'
http   = require 'http'

httputil = require './httputil'


class Proxy
    defaultPort: 8080
    defaultHost: '127.0.0.1'
    serverMem:   []
    bindings:    []
    entries:     []

    start: (conf, callback) ->
        @update conf
        @startServers (err) ->
            if typeof callback is 'function'
                if err then return callback err
                return callback()

        return

    update: (options) ->
        # TODO: Validate configs and emit a warning for invalid configs.

        if not Array.isArray options.entries
            options.entries = [options.entries]

        if not Array.isArray options.bindings
            options.bindings = []

        @entries = options.entries.map normalizeVhostEntry
        @bindings = options.bindings
        return options

    startServers: (callback) ->
        resolved = false
        requestHandler = @makeRequestHandler()

        check = (server) =>
            if server then @serverMem.push server
            if not resolved and @bindings.length >= @serverMem.length
                resolved = true
                if typeof callback is 'function' then callback null

        handleError = (err) ->
            if not resolved
                resolved = true

                if typeof callback is 'function'
                    process.nextTick ->
                        callback err

        if not @bindings.length
            return process.nextTick check

        for binding in @bindings
            binding or= {}
            opts =
                port: binding.port or= @defaultPort
                host: binding.host or= @defaultHost
                requestHandler: requestHandler

            server = httputil.bindServer opts, check
            server.once 'error', handleError

    makeRequestHandler: ->
        handler = (req, res) =>
            vhost = normalizeHost req.headers.host
            entry = @testEntries vhost
            url = null
            host = null
            port = null

            if not entry then return @write404 res, vhost

            if entry.rewrite_rules
                {url, host, port} = @testRewriteRules entry.rewrite_rules, req.url

            proxyOptions =
                host: host or entry.host
                port: port or entry.port
                method: req.method
                path: url or req.url
                headers: req.headers

            return @hookProxy proxyOptions, req, res

        return handler

    servers: ->
        mappedServers = @serverMem.map (server) ->
            rv =
                address: server.address() || {}
                connections: server.connections

            return rv

        return mappedServers

    stop: (callback) ->
        resolved = false
        waiting = 0
        len = @serverMem.length

        checkCallback = ->
            if resolved then return
            waiting += 1
            if waiting >= len
                resolved = true
                if typeof callback is 'function'
                    process.nextTick ->
                        callback()

        if not len
            checkCallback

        while @serverMem.length
            server = @serverMem.shift()

            server.on 'close', checkCallback
            try
                server.close()
            catch err
                checkCallback()

    hookProxy: (proxyOptions, req, res) ->
        # TODO emit a warning for an invalid path:
        if proxyOptions.path.charAt(0) isnt '/'
            proxyOptions.path = "/#{ proxyOptions.path }"

        proxy = http.request proxyOptions, (proxyResponse) ->
            res.writeHead proxyResponse.statusCode, proxyResponse.headers

            proxyResponse.on 'data', (chunk) ->
                res.write chunk

            proxyResponse.on 'end', ->
                res.end()

        proxy.on 'error', (err) =>
            @write500 res, err

        req.on 'data', (chunk) ->
            proxy.write chunk

        req.on 'end', ->
            proxy.end()

        return

    testEntries: (vhost) ->
        for entry in @entries
            if entry.virtual_host is vhost
                return entry

    testRewriteRules: (rules, originalURL) ->
        newURL = originalURL

        for rule in rules
            match = rule.regex.exec originalURL

            if match and rule.url
                newURL = rule.url
                if match.length > 1
                    for i in [1..match.length]
                        newURL = newURL.replace "$#{i}", match[i]

                    return {url: newURL, host: rule.host, port: rule.port}

        return {url: newURL}

    write404: (res, err) ->
        res.writeHead 404, {'content-type': 'text/html'}
        body = "<html><body><p>Error finding a host for virtual host
        <tt>#{ JSON.stringify(err) }</tt></p></body></html>"
        res.end body
        return

    write500: (res, err) ->
        res.writeHead 500, {'content-type': 'text/plain'}
        body = "A server error has been intercepted by proxy: 
        #{ JSON.stringify(err) }"
        res.end body
        return


normalizeHost: (host) ->
    return (if typeof host is 'string' then host else '').toLowerCase()

normalizeVhostEntry = (entry) ->
    entry or= {}
    if typeof entry.virtual_host isnt 'string'
        entry.virtual_host = 'localhost'

    if typeof entry.port isnt 'number'
        entry.port = 8080

    if typeof entry.host isnt 'string'
        entry.host = '127.0.0.1'

        if Array.isArray(entry.rewrite_rules) and entry.rewrite_rules.length
            entry.rewrite_rules = entry.rewrite_rules.map normalizeRewriteRule
        else
        normalize    entry.rewrite_rules = null

    return entry

normalizeRewriteRule = (rule) ->
    rule = if Array.isArray(rule) then rule else []
    rv =
        regex: '^/'
        url: ''
        port: null
        host: null

    if rule.length > 0
        if typeof rule[0] is 'string'
            try
                rv.regex = new RegExp rule[0]
            catch e

    if rule.length > 1
        if typeof rule[1] is 'string'
            rv.url = rule[1]

    if rule.length > 2 and rule[2] and typeof rule[2] is 'object'
        if typeof rule[2].port is 'number'
            rv.port = rule[2].port
        if typeof rule[2].host is 'string'
            rv.host = rule[2].host
    
    return rv


exports.Proxy = Proxy

