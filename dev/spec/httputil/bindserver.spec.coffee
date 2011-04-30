util     = require 'util'
http     = require 'http'
httputil = require '../../../lib/httputil'


describe 'parameters for httputil.bindServer()', ->

    it 'should use sensible defaults', ->
        closed = false
        server = httputil.bindServer()

        server.on 'error', (err) ->
            util.debug "#{ JSON.stringify err }\n"
            expect('failed').toBe null

        server.on 'close', ->
            closed = true

        serverClosed = ->
            return closed

        # Give it some time to get started
        waits 300
        runs ->
            {address, port} = server.address()
            expect(address).toBe '127.0.0.1'
            expect(port).toBe 8080
            testServer()

        # Send a request to test the server
        testServer = ->
            response = false
            reqOpts =
                host: '127.0.0.1'
                port: 8080
                method: 'GET'
                path: '/'

            request = http.request reqOpts, (res) ->
                response = res

            request.on 'error', (err) ->
                util.debug "#{ JSON.stringify err }\n"
                expect('failed').toBe null

            request.end()

            gotResponse = ->
                return response

            waitsFor gotResponse, 'default response', 300
            runs ->
                expect(response.statusCode).toBe 200
                server.close()
                waitsFor serverClosed, 'server to close', 300


    it 'accepts port, host, requestHandler, and onSuccess parameters', ->
        closed = false
        open = false

        requestHandler = (req, res) ->
            res.writeHead 404
            res.end 'ok'

        onSuccess = ->
            open = true

        opts =
            port: 8001
            host: 'localhost'
            requestHandler: requestHandler
            onSuccess: onSuccess

        server = httputil.bindServer opts

        server.on 'error', (err) ->
            util.debug "#{ JSON.stringify err }\n"
            expect('failed').toBe null

        server.on 'close', ->
            closed = true

        serverClosed = ->
            return closed
        serverOpen = ->
            return open

        waitsFor serverOpen, 'server to open', 300
        runs ->
            {address, port} = server.address()
            expect(address).toBe '127.0.0.1'
            expect(port).toBe 8001
            testServer()

        # Send a request to test the server
        testServer = ->
            response = false
            reqOpts =
                host: 'localhost'
                port: 8001
                method: 'GET'
                path: '/'

            request = http.request reqOpts, (res) ->
                response = res

            request.on 'error', (err) ->
                util.debug "#{ JSON.stringify err }\n"
                expect('failed').toBe null

            request.end()

            gotResponse = ->
                return response

            waitsFor gotResponse, 'expected response', 300
            runs ->
                expect(response.statusCode).toBe 404
                server.close()
                waitsFor serverClosed, 'server to close', 300

describe 'bindServer::server error emitter', ->

    it 'should emit error events', ->
        closed = false
        open = false

        onSuccess = ->
            open = true

        opts =
            port: 8001
            host: 'localhost'
            onSuccess: onSuccess

        server = httputil.bindServer opts

        server.on 'error', (err) ->
            util.debug "#{ JSON.stringify err }\n"
            expect('failed').toBe null

        server.on 'close', ->
            closed = true

        serverClosed = ->
            return closed
        serverOpen = ->
            return open

        waitsFor serverOpen, 'server to open', 300
        runs ->
            nextOpen = false

            opts =
                port: 8001
                host: 'localhost'

            nextServer = httputil.bindServer opts

            nextServer.on 'error', (err) ->
                nextOpen = true
                expect(err.code).toBe 'EADDRINUSE'

            nextToBeOpen = ->
                return nextOpen

            waitsFor nextToBeOpen, 'conflicting server', 3000
            runs ->
                server.close()
                waitsFor serverClosed, 'server to close', 300
