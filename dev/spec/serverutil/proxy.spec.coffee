http = require 'http'

serverutil = require '../../../lib/serverutil'
httputil   = require '../../../lib/httputil'

describe 'serverutil HttpProxy.proxyRequest()', ->

    it 'should proxy incoming http GET request to a specified ip and port', ->
        serverRunning = false
        proxiedServerRunning = false

        proxy = new serverutil.HttpProxy()

        server = http.createServer (req, res) ->
            proxyOpts =
                host: '127.0.0.1'
                port: 9090

            return proxy.proxyRequest(req, res, proxyOpts)

        server.listen 8080, 'localhost', ->
            return serverRunning = true

        proxied = http.createServer (req, res) ->
            res.writeHead(200)
            res.end('ok')
            return

        proxied.listen 9090, '127.0.0.1', ->
            return proxiedServerRunning = true

        serversRunning = ->
            return (serverRunning and proxiedServerRunning)

        waitsFor(serversRunning, 'servers to start', 1000)

        runs ->
            client = new httputil.Client({host: 'localhost', port: 8080})
            {check, request} = client.get()

            waitsFor(check, 'request response', 3000)
            runs ->
                server.close()
                proxied.close()

                {response, error} = check()
                expect(response.body).toBe('ok')
        return


    it 'should proxy incoming http POST request to a specified ip and port', ->
        serverRunning = false
        proxiedServerRunning = false

        proxy = new serverutil.HttpProxy()

        server = http.createServer (req, res) ->
            proxyOpts =
                host: '127.0.0.1'
                port: 9090

            return proxy.proxyRequest(req, res, proxyOpts)

        server.listen 8080, 'localhost', ->
            return serverRunning = true

        proxied = http.createServer (req, res) ->
            buff = ''
            req.on 'data', (chunk) ->
                return buff += chunk

            req.on 'end', ->
                expect(buff).toBe 'tester'
                res.writeHead(200)
                return res.end('ok')

            return

        proxied.listen 9090, '127.0.0.1', ->
            return proxiedServerRunning = true

        serversRunning = ->
            return (serverRunning and proxiedServerRunning)

        waitsFor(serversRunning, 'servers to start', 1000)

        runs ->
            client = new httputil.Client({host: 'localhost', port: 8080})
            {check, request} = client.post('/', 'tester')

            waitsFor(check, 'request response', 3000)
            runs ->
                server.close()
                proxied.close()

                {response, error} = check()
                expect(response.body).toBe('ok')

        return


    it 'should proxy a 304 Not Modified response', ->
        serverRunning = false
        proxiedServerRunning = false

        proxy = new serverutil.HttpProxy()

        server = http.createServer (req, res) ->
            proxyOpts =
                host: '127.0.0.1'
                port: 9090

            return proxy.proxyRequest(req, res, proxyOpts)

        server.listen 8080, 'localhost', ->
            return serverRunning = true

        proxied = http.createServer (req, res) ->
            res.writeHead(304)
            res.end()
            return

        proxied.listen 9090, '127.0.0.1', ->
            return proxiedServerRunning = true

        serversRunning = ->
            return (serverRunning and proxiedServerRunning)

        waitsFor(serversRunning, 'servers to start', 1000)

        runs ->
            client = new httputil.Client({host: 'localhost', port: 8080})
            {check, request} = client.get()

            waitsFor(check, 'request response', 3000)
            runs ->
                server.close()
                proxied.close()

                {response, error} = check()
                expect(response.statusCode).toBe(304)
                expect(response.body).toBe('')
        return


    it 'should emit an error event if the target server is not listening', ->
        serverRunning = false
        errorState = false

        proxy = new serverutil.HttpProxy()

        proxy.on 'error', ->
            errorState = true

        server = http.createServer (req, res) ->
            proxyOpts =
                host: '127.0.0.1'
                port: 9090

            return proxy.proxyRequest(req, res, proxyOpts)

        server.listen 8080, 'localhost', ->
            return serverRunning = true

        serversRunning = ->
            return serverRunning

        waitsFor(serversRunning, 'servers to start', 1000)

        runs ->
            client = new httputil.Client({host: 'localhost', port: 8080})
            {check, request} = client.get()

            waitsFor(check, 'request response', 3000)
            runs ->
                server.close()

                expect(errorState).toBe true

                {response, error} = check()
                expect(response.statusCode).toBe(500)
                expect(response.body).toBe('')
        return
