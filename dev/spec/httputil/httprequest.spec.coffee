httputil = require '../../../lib/httputil'

describe 'make GET request with set options', ->
    it 'should return a checker function which provides a response', ->
        client = new httputil.Client('www.google.com')
        {check, request} = client.get()

        waitsFor check, 'client response from www.google.com/', 3000
        runs ->
            expect(typeof check).toBe 'function'
            {error, response} = check()
            expect(typeof response).toBe 'object'
            expect(response.statusCode).toBe 200
            expect(typeof response.body).toBe 'string'
