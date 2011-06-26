httputil = require '../../../lib/httputil'

describe 'normalizeHostString()', ->
    it 'should remove the port portion of the host string', ->
        hostString = httputil.normalizeHostString('example.com:8080')
        expect(hostString).toBe 'example.com'
        return

    it 'should accept a non string and return an empty string', ->
        hostString = httputil.normalizeHostString()
        expect(hostString).toBe ''
        return
