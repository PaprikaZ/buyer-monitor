fs = require('fs')
config = require('../lib/config.js')
rewire = require('rewire')
verdicts = require('./cache/builder.js').generateVerdicts()
monitor = rewire('../lib/monitor.js')

describe('monitor module', ->
  config.accounts = [
    {accessToken: 'testtoken0000'},
    {accessToken: 'testtoken0001'},
    {accessToken: 'testtoken0002'}
  ]
  monitor.__set__({
    logger:
      debug: ->
      warn: ->
      info: ->
      error: ->
    config: config
    fs:
      readFileSync: ->
        return JSON.stringify(verdicts)
    db:
      getClient: -> {rpop: ->}
  })
  createMonitor = monitor.createMonitor

  describe('create monitor', ->
    it('should throw access token empty error when no token found', ->
      revert = monitor.__set__({
        config:
          accounts: []
      })
      createMonitor.should.throw('access tokens empty')
      revert()
      return
    )

    it('should throw verdicts empty error when no verdicts found', ->
      revert = monitor.__set__({
        fs:
          readFileSync: ->
            return JSON.stringify([])
      })
      createMonitor.should.throw('products empty')
      revert()
      return
    )
    return
  )

  describe('verify user tokens', ->
    it('should start monitoring when all verifications done', ->
      counter = 0
      called = false
      revert = monitor.__set__({
        request:
          get: (options, callback) ->
            counter = counter + 1
            callback(null, {statusCode: 200, url: 'www.example.com'}, 'test')
            return
      })
      m = createMonitor()
      m.startMonitoring = ->
        called = true
        counter.should.equal(config.accounts.length)
        return
      m.start()
      called.should.be.true
      revert()
      return
    )

    it('should throw error when all tokens are invalid', ->
      revert = monitor.__set__({
        request:
          get: (options, callback) ->
            callback(new Error('test mock error'))
            return
      })
      m = createMonitor()
      m.startMonitoring = ->
      m.start.bind(m).should.throw('all access token is invalid')
      revert()
      return
    )

    it('should drop invalid tokens when all verifications done', ->
      revert = monitor.__set__({
        request:
          get: (options, callback) ->
            if options.auth.user == 'testtoken0001'
              callback(new Error('test mock error'))
            else
              callback(null, {statusCode: 200, url: 'www.example.com'}, 'test')
            return
      })
      m = createMonitor()
      m.startMonitoring = ->
      m.start()
      m.accessTokens.should.eql(['testtoken0000', 'testtoken0002'])
      revert()
      return
    )
    return
  )

  describe('monitoring', ->
    makeRpop = (queue) ->
      return (key, callback) ->
        if 0 < queue.length
          callback(null, queue.pop())
        else
          callback(null, null)

    revert = null
    beforeEach(->
      revert = monitor.__set__({
        request:
          get: (options, callback) ->
            callback(null, {statusCode: 200, url: 'www.example.com'}, 'test body')
            return
        setInterval: ->
        setTimeout: ->
      })
      return
    )

    after(->
      revert()
      return
    )

    it('should call send requests when push queue clearing done', ->
      v = verdicts.slice().pop()
      queue = [JSON.stringify({id: v.id, site: v.site})]
      revert = monitor.__set__({
        db:
          getClient: ->
            return {rpop: makeRpop(queue)}
      })
      m = createMonitor()
      m.sendRequests = ->
      m.start()
      queue.should.be.empty
      revert()
      return
    )

    it('should bypass database pop error', ->
      revert = monitor.__set__({
        db:
          getClient: ->
           return {rpop: (key, callback) ->
            callback(new Error('test mock error'))
            return
           }
      })
      m = createMonitor()
      m.start.bind(m).should.throw('test mock error')
      revert()
      return
    )

    it('should do nothing when all seeds is delayed', ->
      queue = verdicts
        .map((v) -> {id: v.id, site: v.site})
        .map((v) -> JSON.stringify(v))
      called = false
      revert = monitor.__set__({
        db:
          getClient: ->
            return {rpop: makeRpop(queue)}
        createVisitor: ->
          called = true
          return {visit: ->}
      })
      createMonitor().start()
      called.should.be.false
      revert()
      return
    )

    it('should push back delayed seeds when timeout', ->
      called = false
      v = verdicts.slice().pop()
      queue = [JSON.stringify({id: v.id, site: v.site})]
      seeds = verdicts.slice()
      remainingSeeds = seeds.slice(0, seeds.length - 1)
      m = null
      revert = monitor.__set__({
        db:
          getClient: ->
            return {rpop: makeRpop(queue)}
        setTimeout: (callback, timeout) ->
          called = true
          m.seeds.map((seed) -> {id: seed.id, site: seed.site})
            .should.eql(remainingSeeds.map((verdict) ->
              {id: verdict.id, site: verdict.site}))
          callback()
          m.seeds.map((seed) -> {id: seed.id, site: seed.site})
            .should.eql(seeds.map((verdict) ->
              {id: verdict.id, site: verdict.site}))
          return
      })
      m = createMonitor()
      m.sendRequests = ->
      m.start()
      called.should.be.true
      revert()
      return
    )
    return
  )
  return
)
