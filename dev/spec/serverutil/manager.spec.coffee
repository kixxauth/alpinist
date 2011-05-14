util       = require 'util'
http       = require 'http'
serverutil = require '../../../lib/serverutil'


describe 'serverutil Manager::applyServer()', ->

    it 'should start a server and call the callback', ->
        closed = false
        open = false
        manager = new serverutil.Manager()

        serverOpts =
            port: 8080
            address: '127.0.0.1'
            handler: (req, res) ->
                res.writeHead '201'
                res.end()

        server = manager.applyServer serverOpts, (s) ->
            expect(s).toBe server
            open = true

        server.on 'error', (err) ->
            util.debug "#{ JSON.stringify err }\n"
            expect('failed').toBe null

        server.on 'close', ->
            closed = true

        serverOpen = ->
            return open

        serverClosed = ->
            return closed

        # Give it some time to get started
        waitsFor serverOpen, '201 server to start', 300
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
                expect(response.statusCode).toBe 201
                # Even though we're not testing the close functionality, we
                # still need to close the server here.
                server.close()
                waitsFor serverClosed, 'server to close', 300


describe 'serverutil Manager', ->

    it 'should emit error events', ->
        closed = false
        open = false

        manager = new serverutil.Manager()

        onSuccess = ->
            open = true

        opts =
            port: 8001
            host: 'localhost'

        server = manager.applyServer opts, onSuccess

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
            serverError = false
            managerError = false

            opts =
                port: 8001
                host: 'localhost'

            nextServer = manager.applyServer opts

            nextServer.on 'error', (err) ->
                serverError = true
                expect(err.code).toBe 'EADDRINUSE'

            manager.on 'error', (err) ->
                managerError = true
                expect(err.message).toMatch /localhost:8001/

            errors = ->
                return serverError and managerError

            waitsFor errors, 'conflicting server', 3000
            runs ->
                server.close()
                waitsFor serverClosed, 'server to close', 300
