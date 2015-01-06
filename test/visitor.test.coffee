sinon = require('sinon')
fs = require('fs')
path = require('path')
rewire = require('rewire')
Seed = require('../lib/seed.js').Seed
verdicts = require('./cache/builder.js').generateVerdicts()
pickVerdict = ->
  min = 0
  max = verdicts.length - 1
  idx = Math.floor(Math.random() * (max - min + 1) + min)
  return verdicts[idx]
urlToHtmlTable = require('./cache/html.json')
visitor = rewire('../lib/visitor.js')

describe('visitor', ->
  createVisitor = visitor.createVisitor
  Visitor = visitor.__get__('Visitor')
  visitor.__set__({
    logger:
      debug: ->
      info: ->
      warn: ->
      error: ->
    db:
      getClient: ->
        return {lpush: ->}
  })
  testAmazonCNProduct =
    id: 'testamazoncnid'
    site: 'www.amazon.cn'
    price:
      compare: 'under'
      target: 80
  testAmazonUSProduct =
    id: 'testamazonusid'
    site: 'www.amazon.com'
    discount:
      compare: 'above'
      target: 50
  testAmazonJPProduct =
    id: 'testamazonjpid'
    site: 'www.amazon.co.jp'
    instore:
      compare: 'equal'
      target: true
  testJingDongProduct =
    id: 'testjingdongid'
    site: 'www.jd.com'
    review:
      compare: 'above'
      target: 8
  testUnknownSiteProduct =
    id: 'testunknownsiteid'
    site: 'www.example.com'
    review:
      compare: 'above'
      target: 9

  describe('create', ->
    it('should given amazon cn visitor when seed site be www.amazon.cn', ->
      AmazonCNVisitor = visitor.__get__('AmazonCNVisitor')
      v = createVisitor(new Seed(testAmazonCNProduct))
      v.should.be.a.AmazonCNVisitor
      return
    )

    it('should given amazon us visitor when seed site be www.amazon.com', ->
      AmazonUSVisitor = visitor.__get__('AmazonUSVisitor')
      v = createVisitor(new Seed(testAmazonUSProduct))
      v.should.be.a.AmazonUSVisitor
      return
    )

    it('should given amazon jp visitor when seed site be www.amazon.co.jp', ->
      AmazonJPVisitor = visitor.__get__('AmazonJPVisitor')
      v = createVisitor(new Seed(testAmazonJPProduct))
      v.should.be.a.AmazonJPVisitor
      return
    )

    it('should given jingdong visitor when seed site be www.jd.com', ->
      JingDongVisitor = visitor.__get__('JingDongVisitor')
      v = createVisitor(new Seed(testJingDongProduct))
      v.should.be.a.JingDongVisitor
      return
    )

    it('should throw error when seed site not support', ->
      createVisitor.bind(null, {site: 'www.example.com'})
        .should.throw('no available visitor')
      return
    )
    return
  )

  describe('visit', ->
    it('should transfer control to page handler when everything ok', ->
      called = false
      revert = visitor.__set__({
        request:
          get: (url, callback) ->
            callback(null, {statusCode: 200}, 'test body')
            return
      })
      v = createVisitor(new Seed(testAmazonCNProduct))
      v.processPage = (body) ->
        called = true
        body.should.equal('test body')
        return
      v.visit()
      called.should.be.true
      revert()
      return
    )

    it('should bypass error when request caught error', ->
      revert = visitor.__set__({
        request:
          get: (url, callback) ->
            callback(new Error('test mock error'))
            return
      })
      v = createVisitor(new Seed(testAmazonCNProduct))
      v.visit.bind(v).should.throw('test mock error')
      revert()
      return
    )

    it('should log the response when response is nok', ->
      called = false
      revert = visitor.__set__({
        request:
          get: (url, callback) ->
            callback(null, {statusCode: 201}, 'test body')
            return
      })
      v = createVisitor(new Seed(testAmazonCNProduct))
      v.errorResponseHandler = (res, body) ->
        called = true
        return v.constructor.prototype.errorResponseHandler(res, body)
      v.visit()
      called.should.be.true
      revert()
      return
    )
    return
  )
  return
)
