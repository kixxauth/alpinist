util       = require 'util'
serverutil = require '../../../lib/serverutil'


describe 'default 404 utility', ->

    it 'should output an HTML message with a 404 error code', ->
        writeHead = false
        end = false

        res =
            writeHead: (status, headers) ->
                expect(writeHead).toBe false
                expect(end).toBe false
                expect(status).toBe 404
                expect(headers['content-type']).toBe 'text/html'
                writeHead = true
            end: (b)->
                expect(writeHead).toBe true
                expect(end).toBe false
                expect(b).toMatch /foo/
                end = true

        serverutil.write404 res, 'foo'


describe 'default 500 utility', ->

    it 'should output an plain text message with a 500 error code', ->
        writeHead = false
        end = false

        res =
            writeHead: (status, headers) ->
                expect(writeHead).toBe false
                expect(end).toBe false
                expect(status).toBe 500
                expect(headers['content-type']).toBe 'text/plain'
                writeHead = true
            end: (b)->
                expect(writeHead).toBe true
                expect(end).toBe false
                expect(b).toMatch /Error: foo/
                end = true

        serverutil.write500 res, new Error 'foo'


