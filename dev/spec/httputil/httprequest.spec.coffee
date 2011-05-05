httputil = require '../../../lib/httputil'

describe 'make GET request with set options', ->
    it 'should return a checker function which provides a response', ->
        client = new httputil.Client('example.com')
        {check, request} = client.get()

        expect(check()).toBe null
        waitsFor check, 'client response from www.google.com/', 3000
        runs ->
            expect(typeof check).toBe 'function'
            {error, response} = check()
            expect(typeof response).toBe 'object'
            expect(response.statusCode).toBe 302
            expect(typeof response.body).toBe 'string'

    it 'should return an error object on invalid domain', ->
        client = new httputil.Client('foo')
        {check, request} = client.get()

        waitsFor check, 'client response from foo/', 3000
        runs ->
            {error, response} = check()
            expect(typeof error).toBe 'object'
            expect(error.code).toBe 'ENOTFOUND'
            expect(response).toBe null

    it 'should return an error object on unavailable host', ->
        client = new httputil.Client('0.0.0.0')
        {check, request} = client.get()

        waitsFor check, 'client response from 0.0.0.0', 3000
        runs ->
            {error, response} = check()
            expect(typeof error).toBe 'object'
            expect(error.code).toBe 'ECONNREFUSED'
            expect(response).toBe null

