http = require 'http'

httputil = require '../../../lib/httputil'

describe 'httputil Client.send()', ->
    it 'should return a checker function which provides a response', ->
        client = new httputil.Client('www.google.com')
        {check, request} = client.send({method: 'GET'})

        expect(check()).toBe null
        waitsFor check, 'client response from www.google.com/', 3000
        runs ->
            expect(typeof check).toBe 'function'
            {error, response} = check()
            expect(typeof response).toBe 'object'
            expect(response.statusCode).toBe 200
            expect(typeof response.body).toBe 'string'

    it 'should return an error object on invalid domain', ->
        client = new httputil.Client('foo')
        {check, request} = client.send({method: 'GET'})

        waitsFor check, 'client response from foo/', 3000
        runs ->
            {error, response} = check()
            expect(typeof error).toBe 'object'
            expect(error.code).toBe 'ENOTFOUND'
            expect(response).toBe null

    it 'should return an error object on unavailable host', ->
        client = new httputil.Client('0.0.0.0')
        {check, request} = client.send({method: 'GET'})

        waitsFor check, 'client response from 0.0.0.0', 3000
        runs ->
            {error, response} = check()
            expect(typeof error).toBe 'object'
            expect(error.code).toBe 'ECONNREFUSED'
            expect(response).toBe null

    it 'should accept a port number for the request', ->
        serverRunning = false

        server = http.createServer (req, res) ->
            res.writeHead(200)
            res.end('ok')
            return

        server.listen 8000, 'localhost', ->
            return serverRunning = true

        checkServer = ->
            return serverRunning

        waitsFor(checkServer, 'local server started', 3000)
        runs ->
            client = new httputil.Client()
            {check, request} = client.send({host: 'localhost', port: 8000, method: 'GET'})

            expect(check()).toBe null
            waitsFor check, 'client response from localhost:8000', 3000
            runs ->
                server.close()
                {error, response} = check()
                expect(error).toBe null
                expect(response.body).toBe 'ok'

describe 'httputil Client.get()', ->
    it 'should GET a response from an HTTP URL', ->
        client = new httputil.Client('www.google.com')
        {check, request} = client.get()

        expect(check()).toBe null
        waitsFor check, 'client response from www.google.com/', 3000
        runs ->
            expect(typeof check).toBe 'function'
            {error, response} = check()
            expect(typeof response).toBe 'object'
            expect(response.statusCode).toBe 200
            expect(typeof response.body).toBe 'string'

describe 'httputil Client.post()', ->

    it 'should POST a request to an HTTP URL', ->
        serverRunning = false

        server = http.createServer (req, res) ->
            buff = ''
            req.on 'data', (chunk) ->
                return buff += chunk

            req.on 'end', ->
                expect(buff).toBe 'test'
                res.writeHead(200)
                return res.end('ok')

            return

        server.listen 8080, 'localhost', ->
            return serverRunning = true

        checkServer = ->
            return serverRunning

        waitsFor(checkServer, 'local server started', 3000)
        runs ->
            client = new httputil.Client('localhost')
            {check, request} = client.post('/', 'test')

            expect(check()).toBe null
            waitsFor check, 'client response from localhost:8080', 3000
            runs ->
                server.close()
                {error, response} = check()
                expect(error).toBe null
                expect(response.body).toBe 'ok'

