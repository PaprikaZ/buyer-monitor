rewire = require('rewire')
Seed = require('../lib/seed.js').Seed
#verdicts = require('./cache/builder.js').generateVerdicts()
#randomVerdict = verdicts[Math.floor(Math.random() * verdicts.length)]

describe('visitor module', ->
  visitor = rewire('../lib/visitor.js')
  visitor.__set__({
    logger:
      debug: ->
      info: ->
      warn: ->
      error: ->
    db:
      getClient: ->
        return {lpush: ->}
    createParser: 
      parse: ->
        return {
          title: 'test title'
          price: 100
          fullPrice: 200
          review: 9
          instore: true
          benefits: []
          discount: 50
        }
  })
  createVisitor = visitor.createVisitor
  AmazonCNVisitor = visitor.__get__('AmazonCNVisitor')
  AmazonUSVisitor = visitor.__get__('AmazonUSVisitor')
  AmazonJPVisitor = visitor.__get__('AmazonJPVisitor')
  JingDongVisitor = visitor.__get__('JingDongVisitor')
  testAmazonCNVerdict =
    id: 'testamazoncnid'
    site: 'www.amazon.cn'
    price:
      compare: 'under'
      target: 80
  testAmazonCNSeed = new Seed(testAmazonCNVerdict)
  testAmazonUSVerdict =
    id: 'testamazonusid'
    site: 'www.amazon.com'
    discount:
      compare: 'above'
      target: 50
  testAmazonUSSeed = new Seed(testAmazonUSVerdict)
  testAmazonJPVerdict =
    id: 'testamazonjpid'
    site: 'www.amazon.co.jp'
    instore:
      compare: 'equal'
      target: true
  testAmazonJPSeed = new Seed(testAmazonJPVerdict)
  testJingDongVerdict =
    id: 'testjingdongid'
    site: 'www.jd.com'
    review:
      compare: 'above'
      target: 8
  testJingDongSeed = new Seed(testJingDongVerdict)

  describe('create visitor', ->
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
      restore = visitor.__set__({
        invalidSiteHandler: ->
      })
      return
    )
    afterEach(-> restore())

    it('should given amazon cn visitor when seed site be www.amazon.cn', ->
      v = createVisitor(testAmazonCNSeed)
      v.should.be.a.AmazonCNVisitor
      return
    )

    it('should given amazon us visitor when seed site be www.amazon.com', ->
      AmazonUSVisitor = visitor.__get__('AmazonUSVisitor')
      v = createVisitor(testAmazonUSSeed)
      v.should.be.a.AmazonUSVisitor
      return
    )

    it('should given amazon jp visitor when seed site be www.amazon.co.jp', ->
      AmazonJPVisitor = visitor.__get__('AmazonJPVisitor')
      v = createVisitor(testAmazonJPSeed)
      v.should.be.a.AmazonJPVisitor
      return
    )

    it('should given jingdong visitor when seed site be www.jd.com', ->
      JingDongVisitor = visitor.__get__('JingDongVisitor')
      v = createVisitor(testJingDongSeed)
      v.should.be.a.JingDongVisitor
      return
    )

    it('should route to invalid site handler when seed site not support', ->
      visitor.__set__('invalidSiteHandler', makeCalledTrue)
      createVisitor({site: 'www.example.com'})
      called.should.be.true
      return
    )
    return
  )

  describe('visit', ->
    called = false
    makeCalledTrue = ->
      called = true
      return
    makeCalledFalse = ->
      called = true
      return
    restore = null
    beforeEach(->
      makeCalledFalse()
      restore = visitor.__set__({
        request:
          get: ->
        requestErrorHandler: ->
        responseErrorHandler: ->
      })
      return
    )
    afterEach(-> restore())

    it('should route to page process when request ok', ->
      visitor.__set__({
        request:
          get: (url, callback) ->
            callback(null, {statusCode: 200}, 'foo')
            return
      })
      v = createVisitor(testAmazonCNSeed)
      v.processPage = (body) ->
        makeCalledTrue()
        body.should.equal('foo')
        return
      v.visit()
      called.should.be.true
      return
    )

    it('should route to request error handler when request caught error', ->
      visitor.__set__({
        request:
          get: (url, callback) ->
            callback(new Error('test mock error'))
            return
        requestErrorHandler: (visitor, url, err) ->
          makeCalledTrue()
          visitor.should.equal(AmazonCNVisitor)
          err.message.should.equal('test mock error')
          return
      })
      v = createVisitor(testAmazonCNSeed)
      v.visit()
      called.should.be.true
      return
    )

    it('should route to response error handler when response nok', ->
      visitor.__set__({
        request:
          get: (url, callback) ->
            callback(null, {statusCode: -1}, 'bar')
            return
        responseErrorHandler: (visitor, res, body) ->
          makeCalledTrue()
          visitor.should.equal(AmazonCNVisitor)
          body.should.equal('bar')
          return
      })
      v = createVisitor(testAmazonCNSeed)
      v.visit()
      called.should.be.true
      return
    )
    return
  )

  describe('request error handler', ->
    requestErrorHandler = visitor.__get__('requestErrorHandler')
    it('should throw error', ->
      requestErrorHandler.bind(null, AmazonCNVisitor, '', new Error('mock error'))
        .should.throw('mock error')
      return
    )
    return
  )

  describe('response error handler', ->
    responseErrorHandler = visitor.__get__('responseErrorHandler')
    it('should not throw error', ->
      responseErrorHandler.bind(
        null, AmazonCNVisitor, {statusCode: -1, url: 'www.amazon.cn'}, 'foo'
      ).should.not.throw()
      return
    )
    return
  )

  describe('invalid site handler', ->
    invalidSiteHandler = visitor.__get__('invalidSiteHandler')
    it('should throw error', ->
      invalidSiteHandler.bind(null, 'www.example.com')
        .should.throw('invalid data error, no available visitor for invalid site')
      return
    )
    return
  )
  return
)
