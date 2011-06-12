httputil = require '../../../lib/httputil'
alpinist = require '../../../alpinist'

describe 'Alpinist::createServer()', ->
    
    it 'should create a server listening on 127.0.0.1:8080 by default', ->
        serverRunning = false
        client = new httputil.Client('127.0.0.1')
        server = alpinist.createServer()
        server.listen ->
            return serverRunning = true

        checkServer = ->
            return serverRunning

        waitsFor(checkServer, 'server to start', 1000)
        runs ->
            expect(server.host()).toBe 'http://127.0.0.1:8080'
            {check, request} = client.get()
            waitsFor(check, 'request to 127.0.0.1:8080', 1000)
            runs ->
                server.close ->
                    serverRunning = false

                {error, response} = check()
                expect(error).toBeFalsy()
                expect(response.statusCode).toBe 404

                serverStopped = ->
                    return (not serverRunning)

                waitsFor(serverStopped, 'server to stop', 1000)
                return
            return
        return
    
    it 'should allow middleware to be added', ->
        serverRunning = false
        client = new httputil.Client({host: '127.0.0.1', port: 8000})

        first = (req, res, next) ->
            res.writeHead(200, {'Content-Type':'text/plain'})
            return next()

        second = (req, res, next) ->
            res.write('hello world')
            return next()

        last = (req, res, next) ->
            return res.end('\n')

        server = alpinist.createServer(first, second, last)

        server.listen 8000, '127.0.0.1', ->
            return serverRunning = true

        checkServer = ->
            return serverRunning

        waitsFor(checkServer, 'server to start', 1000)
        runs ->
            expect(server.host()).toBe 'http://127.0.0.1:8000'
            {check, request} = client.get()
            waitsFor(check, 'request to 127.0.0.1:8080', 1000)
            runs ->
                server.close ->
                    serverRunning = false

                {error, response} = check()
                expect(error).toBeFalsy()
                expect(response.statusCode).toBe 200
                expect(response.body).toBe 'hello world\n'

                serverStopped = ->
                    return (not serverRunning)

                waitsFor(serverStopped, 'server to stop', 1000)
                return
            return
        return
