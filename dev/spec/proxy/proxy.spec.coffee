proxy = require '../../../lib/proxy'

describe 'bound proxy servers', ->

    it 'should start and stop servers', ->
        proxy = new proxy.Proxy()
