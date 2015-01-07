config = require('../lib/config.js')
rewire = require('rewire')
verdicts = require('./cache/builder.js').generateVerdicts()
testTokens = [
  {accessToken: 'testtoken0000'},
  {accessToken: 'testtoken0001'},
  {accessToken: 'testtoken0002'}
]
config.accounts = testTokens

describe('monitor module', ->
  monitor = rewire('../lib/monitor.js')
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
    messenger:
      push: ->
    token:
      verify: ->
      isVerificationDone: -> true
      getValidTokens: config.accounts
    createVisitor: -> {visit: ->}
  })
  createMonitor = monitor.createMonitor

  describe('create monitor', ->
    it('should throw error when no token configured', ->
      restore = monitor.__set__('config', {accounts: []})
      createMonitor.should.throw('config error, access tokens empty')
      restore()
      return
    )

    it('should throw error when no verdicts configured', ->
      restore = monitor.__set__({
        fs:
          readFileSync: ->
            return JSON.stringify([])
      })
      createMonitor.should.throw('config error, verdicts empty')
      restore()
      return
    )
    return
  )

  describe('process delay queue', ->
    makeRpop = (queue) ->
      return (key, callback) ->
        if 0 < queue.length
          callback(null, queue.pop())
        else
          callback(null, null)

    called = false
    makeCalledTrue = ->
      called = true
      return
    makeCalledFalse = ->
      called = false
      return
    restore = null
    beforeEach(->
      makeCalledFalse()
      restore = monitor.__set__({
        setInterval: ->
        setTimeout: ->
        db:
          getClient: -> {rpop: ->}
        createVisitor: -> {visit: ->}
      })
      return
    )
    afterEach(-> restore())

    it('should visit sites after delay queue cleared ', ->
      v = verdicts.slice().pop()
      queue = [JSON.stringify({id: v.id, site: v.site})]
      monitor.__set__({
        db:
          getClient: -> {rpop: makeRpop(queue)}
      })
      m = createMonitor()
      m.visitSites = makeCalledTrue
      m.processDelayQueue()
      queue.should.be.empty
      called.should.be.true
      return
    )

    it('should bypass database error', ->
      monitor.__set__({
        db:
          getClient: -> {rpop: (key, callback) -> callback(new Error('foo'))}
      })
      m = createMonitor()
      m.processDelayQueue.bind(m).should.throw('foo')
      return
    )

    it('should not visit any site when all seeds delayed', ->
      queue = verdicts
        .map((v) -> {id: v.id, site: v.site})
        .map((v) -> JSON.stringify(v))
      monitor.__set__({
        db:
          getClient: -> {rpop: makeRpop(queue)}
        createVisitor: ->
          makeCalledTrue()
          return {visit: ->}
      })
      createMonitor().processDelayQueue()
      called.should.be.false
      return
    )

    it('should push back delayed seeds when timeout', ->
      v = verdicts.slice().pop()
      queue = [JSON.stringify({id: v.id, site: v.site})]

      vdts = verdicts.slice()
      remainingVdts = vdts.slice(0, vdts.length - 1)
      m = null
      monitor.__set__({
        db:
          getClient: -> {rpop: makeRpop(queue)}
        setTimeout: (callback, timeout) ->
          makeCalledTrue()
          m.seeds.map((seed, idx) -> seed.equal(remainingVdts[idx]).should.be.true)
          callback()
          m.seeds.map((seed, idx) -> seed.equal(vdts[idx]).should.be.true)
          return
      })
      m = createMonitor()
      m.visitSites = ->
      m.processDelayQueue()
      called.should.be.true
      return
    )
    return
  )

  describe('process push queue', ->
    makeRpop = (queue) ->
      return (key, callback) ->
        if 0 < queue.length
          callback(null, queue.pop())
        else
          callback(null, null)

    called = false
    makeCalledTrue = ->
      called = true
      return
    makeCalledFalse = ->
      called = false
      return
    restore = null
    beforeEach(->
      makeCalledFalse()
      restore = monitor.__set__({
        setInterval: ->
        setTimeout: ->
        db:
          getClient: -> {rpop: ->}
        messenger:
          push: ->
      })
      return
    )
    afterEach(-> restore())

    it('should push messages after push queue cleared', ->
      monitor.__set__({
        db:
          getClient: -> {rpop: makeRpop([])}
      })
      m = createMonitor()
      m.pushMessages = makeCalledTrue
      m.processPushQueue()
      called.should.be.true
      return
    )

    it('should bypass database error', ->
      monitor.__set__({
        db:
          getClient: -> {rpop: (key, callback) -> callback(new Error('foo'))}
      })
      m = createMonitor()
      m.processPushQueue.bind(m).should.throw('foo')
      return
    )

    it('should not push any message when push queue empty', ->
      monitor.__set__({
        db:
          getClient: -> {rpop: makeRpop([])}
        messenger:
          push: makeCalledTrue
      })
      m = createMonitor()
      m.processPushQueue()
      called.should.be.false
      return
    )
    return
  )
  return
)
