rewire = require('rewire')

describe('messenger module', ->
  messenger = rewire('../lib/messenger.js')
  messenger.__set__({
    logger:
      debug: ->
      info: ->
      error: ->
  })

  testID = 'test0000'
  testSite = 'www.example.com'
  testUrl = 'www.example.com/pd/test0000'
  testToken = 'ffffffff'
  mockErrorMsg = 'mock request error'

  describe('assemble message title', ->
    assembleMessageTitle = messenger.__get__('assembleMessageTitle')

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
      restore = messenger.__set__({
        fieldMissingHandler: ->
      })
      return
    )
    afterEach(-> restore())

    it('should return title when result owns base fields', ->
      testResult =
        id: testID
        site: testUrl
        url: testUrl
      assembleMessageTitle(testResult).should.be.a.String
      return
    )

    it('should route to field missing handler when result id missing', ->
      testResult =
        site: testSite
        url: testUrl
      messenger.__set__({
        fieldMissingHandler: makeCalledTrue
      })
      assembleMessageTitle(testResult)
      called.should.be.true
      return
    )

    it('should route to field missing handler when result site missing', ->
      testResult =
        id: testID
        url: testUrl
      messenger.__set__({
        fieldMissingHandler: makeCalledTrue
      })
      assembleMessageTitle(testResult)
      called.should.be.true
      return
    )
    return
  )

  describe('assemble message body', ->
    assembleMessageBody = messenger.__get__('assembleMessageBody')

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
      restore = messenger.__set__({
        fieldMissingHandler: ->
      })
      return
    )
    afterEach(-> restore())

    it('should return body when result own all parsed fields', ->
      testResult =
        id: testID
        site: testSite
        url: testUrl
        title: 'product test title'
        price: 1
        fullPrice: 1
        discount: 10
        review: 9
        instore: true
        benefits: []
      assembleMessageBody(testResult).should.be.String
      return
    )

    it('should route to field missing handler when some parse fields missing', ->
      testResult =
        id: testID
        site: testSite
        url: testUrl
        title: 'product test title'
        price: 1
        discount: 10
        review: 9
        instore: true
        benefits: []
      messenger.__set__({
        fieldMissingHandler: makeCalledTrue
      })
      assembleMessageBody(testResult)
      called.should.be.true
      return
    )
    return
  )

  describe('push', ->
    push = messenger.__get__('push')
    result =
      id: testID
      site: testSite
      url: testUrl
      title: 'product test title'
      price: 1
      fullPrice: 1
      discount: 10
      review: 9
      instore: true
      benefits: []

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
      restore = messenger.__set__({
        responseErrorHandler: ->
        requestErrorHandler: ->
        request:
          post: ->
      })
      return
    )
    afterEach(-> restore())

    it('should not throw error when http post success', ->
      messenger.__set__({
        request:
          post: (url, callback) ->
            makeCalledTrue()
            callback(null, {statusCode: 200}, '')
            return
      })
      push.bind(null, result, testToken).should.not.throw()
      called.should.be.true
      return
    )

    it('should route to response error handler when response nok', ->
      messenger.__set__({
        request:
          post: (url, callback) ->
            callback(null, {statusCode: -1}, '')
            return
        responseErrorHandler: makeCalledTrue
      })
      push(result, testToken)
      called.should.be.true
      return
    )

    it('should route to request error handler when request caught error', ->
      messenger.__set__({
        request:
          post: (url, callback) ->
            callback(new Error(mockErrorMsg))
            return
        requestErrorHandler: makeCalledTrue
      })
      push(result, testToken)
      called.should.be.true
      return
    )
    return
  )

  describe('field missing handler', ->
    fieldMissingHandler = messenger.__get__('fieldMissingHandler')
    it('should throw error', ->
      fieldMissingHandler.bind(null, 'foo')
        .should.throw('data error, missing necessary fields')
      return
    )
    return
  )

  describe('response error handler', ->
    responseErrorHandler = messenger.__get__('responseErrorHandler')
    it('should throw error', ->
      responseErrorHandler.bind(
        null, testToken, {url: testSite, statusCode: -1}, '')
        .should.throw('push message response error')
      return
    )
    return
  )

  describe('request error handler', ->
    requestErrorHandler = messenger.__get__('requestErrorHandler')
    it('should throw error', ->
      requestErrorHandler.bind(null, testToken, new Error(mockErrorMsg))
        .should.throw(mockErrorMsg)
      return
    )
    return
  )
  return
)
