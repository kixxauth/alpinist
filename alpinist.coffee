serverutil = require './lib/serverutil'
modStack   = require './lib/third_party/stack/stack'

exports.ProxyProcessor = serverutil.ProxyProcessor

manager = new serverutil.Manager()


class Server
    server: null
    handler: null

    constructor: (handler) ->
        @server = null
        if typeof handler is 'function' then @handler = handler
        else
            @handler = (req, res) ->
                return serverutil.write404(res)

    listen: (port, host, callback) ->
        if not callback and typeof host is 'function'
            callback = host
            host = null
        if not callback and typeof port is 'function'
            callback = port
            port = null

        serverOpts =
            handler: @handler

        if typeof port isnt 'number'
            serverOpts.port = 8080
        else serverOpts.port = port

        if not host or typeof host isnt 'string'
            serverOpts.host = '127.0.0.1'
        else serverOpts.host = host

        @server = manager.applyServer serverOpts, ->
            if typeof callback is 'function'
                callback()
            return
        return

    close: (callback) ->
        @server.once 'close', ->
            if typeof callback is 'function'
                callback()
            return

        @server.close()
        return @

    host: ->
        {address, port} = @server.address()
        return "http://#{ address }:#{ port }"


createServer = ->
    return new Server(modStack.stack.apply({}, arguments))

exports.createServer = createServer
