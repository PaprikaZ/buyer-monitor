rewire = require('rewire')
messenger = rewire('../lib/messenger.js')

describe('messenger', ->
  messenger.__set__({
    logger:
      debug: ->
      info: ->
      error: ->
    console:
      log: ->
      error: ->
  })

  describe('assemble message title', ->
    assembleMessageTitle = messenger.__get__('assembleMessageTitle')
    it('should return string when result own all product base fields', ->
      testResult =
        id: 'test0000'
        site: 'www.example.com'
        url: 'www.example.com/pd/test0000'
      assembleMessageTitle(testResult).should.be.a.String
      return
    )

    it('should route to result error handler when result id is missing', ->
      called = false
      testResult =
        site: 'www.example.com'
        url: 'www.example.com/pd/test0000'
      revert = messenger.__set__({
        resultErrorHandler: ->
          called = true
          return
      })
      assembleMessageTitle(testResult)
      called.should.be.true
      revert()
      return
    )

    it('should route to result error handler when result site is missing', ->
      called = false
      testResult =
        id: 'test0000'
        url: 'www.example.com/pd/test0000'
      revert = messenger.__set__({
        resultErrorHandler: ->
          called = true
          return
      })
      assembleMessageTitle(testResult)
      called.should.be.true
      revert()
      return
    )
    return
  )

  describe('assemble message body', ->
    assembleMessageBody = messenger.__get__('assembleMessageBody')

    it('should return string when result own all parse fields', ->
      testResult =
        id: 'test0000'
        site: 'www.example.com'
        url: 'www.example.com/pd/test0000'
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

    it('should route to result error handler when parse fields of result is missing', ->
      called = false
      testResult =
        id: 'test0000'
        site: 'www.example.com'
        url: 'www.example.com/pd/test0000'
      revert = messenger.__set__({
        resultErrorHandler: ->
          called = true
          return
      })
      assembleMessageBody(testResult)
      called.should.be.true
      revert()
      return
    )
    return
  )

  describe('push', ->
    push = messenger.__get__('push')
    called = false
    makeCalledTrue = ->
      called = true
      return
    beforeEach(->
      called = false
      return
    )
    result =
      id: 'test0000'
      site: 'www.example.com'
      url: 'www.example.com/pd/test0000'
      title: 'product test title'
      price: 1
      fullPrice: 1
      discount: 10
      review: 9
      instore: true
      benefits: []

    it('should log push success message when http post response ok', ->
      revert = messenger.__set__({
        accessTokens: ['ffffffff']
        logger:
          debug: ->
          info: (log) ->
            if /^push message to user/.test(log)
              makeCalledTrue()
            return
          error: ->
        request:
          post: (url, callback) ->
            callback(null, {statusCode: 200}, '')
            return
      })
      push(result)
      called.should.be.true
      revert()
      return
    )

    it('should first assemble message title', ->
      revert = messenger.__set__({
        accessTokens: ['ffffffff']
        assembleMessageTitle: makeCalledTrue
      })
      push(result)
      called.should.be.true
      revert()
      return
    )

    it('should first assemble message body', ->
      revert = messenger.__set__({
        accessTokens: ['ffffffff']
        assembleMessageBody: makeCalledTrue
      })
      push(result)
      called.should.be.true
      revert()
      return
    )

    it('should send http post request when there is available user tokens', ->
      revert = messenger.__set__({
        accessTokens: ['ffffffff']
        request:
          post: makeCalledTrue
      })
      push(result)
      called.should.be.true
      revert()
      return
    )

    it('should route to token empty handler when no available access tokens', ->
      revert = messenger.__set__({
        accessTokens: []
        tokenEmptyHandler: makeCalledTrue
      })
      push(result)
      called.should.be.true
      revert()
      return
    )

    it('should route to response error handler when status code not equal to 200', ->
      revert = messenger.__set__({
        accessTokens: ['ffffffff']
        request:
          post: (url, callback) ->
            callback(null, {statusCode: -1}, '')
            return
        responseErrorHandler: makeCalledTrue
      })
      push(result)
      called.should.be.true
      revert()
      return
    )

    it('should route to request error handler when request caught error', ->
      mockErrorMsg = 'mock request error'
      revert = messenger.__set__({
        accessTokens: ['ffffffff']
        request:
          post: (url, callback) ->
            callback(new Error(mockErrorMsg), null, null)
            return
        requestErrorHandler: makeCalledTrue
      })
      push(result)
      called.should.be.true
      revert()
      return
    )
    return
  )

  describe('token empty handler', ->
    tokenEmptyHandler = messenger.__get__('tokenEmptyHandler')

    it('should throw empty error', ->
      tokenEmptyHandler.should.throw('no available tokens')
    )
    return
  )

  describe('result error handler', ->
    resultErrorHandler = messenger.__get__('resultErrorHandler')

    it('should throw result error', ->
      resultErrorHandler.should.throw('result attributes error')
      return
    )
    return
  )

  describe('response error handler', ->
    responseErrorHandler = messenger.__get__('responseErrorHandler')

    it('should throw response error', ->
      responseErrorHandler.bind(null, 'ffffffff', {statusCode: -1}, '')
        .should.throw('push message response error')
      return
    )
    return
  )

  describe('request error handler', ->
    requestErrorHandler = messenger.__get__('requestErrorHandler')
    mockErrorMsg = 'mock request error'

    it('should throw request error', ->
      requestErrorHandler.bind(null, 'ffffffff', new Error(mockErrorMsg))
        .should.throw(mockErrorMsg)
      return
    )
    return
  )
  return
)
