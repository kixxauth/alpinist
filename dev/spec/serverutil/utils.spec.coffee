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


describe 'RewriteRule', ->

    it 'Should create a default .regex propery if not in the spec', ->
        rr = new serverutil.RewriteRule()
        expect(rr.regex.ignoreCase).toBe(true)
        expect(rr.regex.source).toBe('^/')

    it 'Should accept a regex spec', ->
        rr = new serverutil.RewriteRule({regex: '^\/home/page$'})
        expect(rr.regex.ignoreCase).toBe(true)
        expect(rr.regex.source).toBe('^\/home/page$')
        expect(typeof rr.regex.exec).toBe('function')

    it 'Should create a default .path propery if not in the spec', ->
        rr = new serverutil.RewriteRule()
        expect(rr.path).toBe('/')

    it 'Should accept a path spec', ->
        rr = new serverutil.RewriteRule({path: '/home/page'})
        expect(rr.path).toBe('/home/page')

    it 'Should create a default .host propery if not in the spec', ->
        rr = new serverutil.RewriteRule()
        expect(rr.host).toBe('127.0.0.1')

    it 'Should accept a host spec', ->
        rr = new serverutil.RewriteRule({host: '58.23.46.1'})
        expect(rr.host).toBe('58.23.46.1')

    it 'Should create a default .port propery if not in the spec', ->
        rr = new serverutil.RewriteRule()
        expect(rr.port).toBe(0)

    it 'Should accept a host port', ->
        rr = new serverutil.RewriteRule({port: 8080})
        expect(rr.port).toBe(8080)


describe 'rewriteURL()', ->

    it 'should return the path if no rules are passed', ->
        newURL = serverutil.rewriteURL('/foopath')
        expect(newURL.path).toBe '/foopath'

    it 'should return the path if no rules are matched', ->
        rules = [{regex: /^\/barpath$/}]
        newURL = serverutil.rewriteURL('/foopath', rules)
        expect(newURL.path).toBe '/foopath'

    it 'should return the path if no rewrite path is given', ->
        rules = [{regex: /^\/foopath$/}]
        newURL = serverutil.rewriteURL('/foopath', rules)
        expect(newURL.path).toBe '/foopath'

    it 'should rewrite the path if a rule matches and a path is given', ->
        rules = [{regex: /^\/foopath$/, path: '/bar/path'}]
        newURL = serverutil.rewriteURL('/foopath', rules)
        expect(newURL.path).toBe '/bar/path'

    it 'should return a host if the matched rule has a host', ->
        rules = [{regex: /^\/foopath$/, host: 'example.com'}]
        newURL = serverutil.rewriteURL('/foopath', rules)
        expect(newURL.host).toBe 'example.com'

    it 'should not return a host if the matched rule has an invalid host', ->
        rules = [{regex: /^\/foopath$/, host: []}]
        newURL = serverutil.rewriteURL('/foopath', rules)
        expect(newURL.host).toBeFalsy()

    it 'should return a port if the matched rule has a port', ->
        rules = [{regex: /^\/foopath$/, port: 8000}]
        newURL = serverutil.rewriteURL('/foopath', rules)
        expect(newURL.port).toBe 8000

    it 'should not return a port if the matched rule has an invalid port', ->
        rules = [{regex: /^\/foopath$/, port: {}}]
        newURL = serverutil.rewriteURL('/foopath', rules)
        expect(newURL.port).toBeFalsy()

    it 'should not perform regex replacement if there is no group match', ->
        rules = [{regex: /^\/foopath\//, path: '/barpath/$1'}]
        newURL = serverutil.rewriteURL('/foopath/', rules)
        expect(newURL.path).toBe '/barpath/$1'

    it 'should not perform regex replacement if there is no target string', ->
        rules = [{regex: /^\/foopath\/(.*)/}]
        newURL = serverutil.rewriteURL('/foopath/bar123', rules)
        expect(newURL.path).toBe '/foopath/bar123'

    it 'should perform regex replacement with group match and target string', ->
        rules = [{regex: /^\/foopath\/([a-z]*)\/uid\/(.*)/, path: '/barpath/$1/id/$2'}]
        newURL = serverutil.rewriteURL('/foopath/val/uid/123qwe', rules)
        expect(newURL.path).toBe '/barpath/val/id/123qwe'

    it 'should stop matching after the first match', ->
        rules = [
            {regex: /^\/foopath\/([0-9]+)/, path: '/barpath/$1/id/$2'}
            {regex: /^\/foopath\/page$/, path: '/barpath/page'}
            {regex: /^\/barpath\/item$/, path: '/barpath/item/page'}
        ]
        newURL = serverutil.rewriteURL('/foopath/page', rules)
        expect(newURL.path).toBe '/barpath/page'


