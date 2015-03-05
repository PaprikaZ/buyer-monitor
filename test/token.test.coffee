rewire = require('rewire')

describe('token module', ->
  token = rewire('../lib/token.js')
  verify = token.verify
  isVerificationDone = token.isVerificationDone
  getValidTokens = token.getValidTokens
  testTokens = ['testtoken0000', 'testtoken0001', 'testtoken0002']

  describe('verify', ->
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
      restore = token.__set__({
        logger:
          debug: ->
          info: ->
          warn: ->
          error: ->
        request:
          get: (options, callback) ->
            callback(null, {statusCode: 200, url: 'www.example.com'}, 'foo')
            return
      })
    )
    afterEach(-> restore())

    it('should change verifications done to true only after all tokens verified', ->
      counter = testTokens.length
      token.__set__({
        request:
          get: (options, callback) ->
            isVerificationDone().should.be.false
            counter = counter - 1
            callback(null, {statusCode: 200, url: 'www.example.com'}, 'foo')
            if 0 == counter
              makeCalledTrue()
              isVerificationDone().should.be.true
            else
              isVerificationDone().should.be.false
            return
      })
      verify(testTokens)
      isVerificationDone().should.be.true
      called.should.be.true
      return
    )
  
    it('should drop invalid tokens after all tokens verified', ->
      token.__set__({
        request:
          get: (options, callback) ->
            makeCalledTrue()
            if options.auth.user == 'testtoken0001'
              callback(new Error('foo'))
            else if options.auth.user == 'testtoken0002'
              callback(null, {statusCode: -1, url: 'www.example.com'})
            else
              callback(null, {statusCode: 200, url: 'www.example.com'}, 'foo')
            return
      })
      verify(testTokens)
      getValidTokens().should.eql(['testtoken0000'])
      called.should.be.true
      return
    )

    it('should throw error when all tokens are invalid', ->
      token.__set__({
        request:
          get: (options, callback) ->
            makeCalledTrue()
            callback(new Error('foo'))
            return
      })
      verify.bind(null, testTokens).should.throw('config error, all token invalid')
      called.should.be.true
      return
    )

    it('should not throw error when request caught error', ->
      token.__set__({
        request:
          get: (options, callback) ->
            makeCalledTrue()
            if options.auth.user == 'testtoken0000'
              callback(new Error('foo'))
            else
              callback(null, {statusCode: 200, url: 'www.example.com'}, 'foo')
            return
      })
      verify.bind(null, testTokens).should.not.throw()
      called.should.be.true
      return
    )

    it('should not throw error when response nok', ->
      token.__set__({
        request:
          get: (options, callback) ->
            makeCalledTrue()
            if options.auth.user == 'testtoken0000'
              callback(null, {statusCode: -1, url: 'www.example.com'})
            else
              callback(null, {statusCode: 200, url: 'www.example.com'}, 'foo')
            return
      })
      verify.bind(null, testTokens).should.not.throw()
      called.should.be.true
      return
    )
    return
  )
  return
)
