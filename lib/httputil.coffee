util = require 'util'
http = require 'http'

# HTTP client interface
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
        util.debug "host #{opts.host} port #{opts.port}"

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
