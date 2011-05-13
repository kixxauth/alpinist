proxy = require '../../../lib/proxy'

describe 'bound proxy servers', ->

    it 'should start and stop servers', ->
        proxy = new proxy.Proxy()

        # Assert that a proxy server is not already running
        expect(proxy.servers().length).toBe 0
