rewire = require('rewire')

describe('argv parser module', ->
  argvParser = rewire('../lib/argv_parser.js')
  argvParser.__set__({
    console:
      log: ->
      info: ->
      warn: ->
      error: ->
  })

  describe('parse', ->
    parse = argvParser.parse

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
      restore = argvParser.__set__({
        addHandler: ->
        removeHandler: ->
        listHandler: ->
        resetHandler: ->
        helpHandler: ->
        unknownArgvHandler: ->
        missingArgHandler: ->
      })
      return
    )
    afterEach(-> restore())

    it('should call callback when no command given', ->
      parse([], makeCalledTrue)
      called.should.be.true
      return
    )

    it('should route to add handler when add arguments given', ->
      argvParser.__set__('addHandler', makeCalledTrue)
      parse(['add', 'foo'], ->)
      called.should.be.true
      return
    )

    it('should route to unknown argv handler when single add given', ->
      argvParser.__set__('unknownArgvHandler', makeCalledTrue)
      parse(['add'], ->)
      called.should.be.true
      return
    )

    it('should route to remove handler when remove arguments given', ->
      argvParser.__set__('removeHandler', makeCalledTrue)
      parse(['remove', 'foo'], ->)
      called.should.be.true
      return
    )

    it('should route to unknown argv handler when single remove given', ->
      argvParser.__set__('unknownArgvHandler', makeCalledTrue)
      parse(['remove'], ->)
      called.should.be.true
      return
    )

    it('should route to list handler when single list given', ->
      argvParser.__set__('listHandler', makeCalledTrue)
      parse(['list'], ->)
      called.should.be.true
      return
    )

    it('should route to unknown argv handler when list followed by arguments', ->
      argvParser.__set__('unknownArgvHandler', makeCalledTrue)
      parse(['list', 'foo'], ->)
      called.should.be.true
      return
    )

    it('should route to reset handler when single reset given', ->
      argvParser.__set__('resetHandler', makeCalledTrue)
      parse(['reset'], ->)
      called.should.be.true
      return
    )

    it('should route to unknown argv handler when reset followed by arguments', ->
      argvParser.__set__('unknownArgvHandler', makeCalledTrue)
      parse(['reset', 'foo'], ->)
      called.should.be.true
      return
    )

    it('should route to help handler when single help given', ->
      argvParser.__set__('helpHandler', makeCalledTrue)
      parse(['help'], ->)
      called.should.be.true
      return
    )

    it('should route to unknown argv handler when help followed by arguments', ->
      argvParser.__set__('unknownArgvHandler', makeCalledTrue)
      parse(['help', 'foo'], ->)
      called.should.be.true
      return
    )

    it('should route to unknown argv handler when arguments unknown', ->
      argvParser.__set__('unknownArgvHandler', makeCalledTrue)
      parse(['foo'], ->)
      called.should.be.true
      return
    )
    return
  )

  describe('add handler', ->
    addHandler = argvParser.__get__('addHandler')
    fullVerdict =
      id: 'test0000'
      site: 'www.example.com'
      price:
        compare: 'under'
        target: 100
      discount:
        compare: 'above'
        target: 20
      review:
        compare: 'above'
        target: 8
      instore:
        compare: 'equal'
        target: true
      benefits:
        compare: 'match'
        target:
          regex: '20% off'
          option: 'i'
    simpleVerdict =
      id: 'test0000'
      site: 'www.example.com'
      price:
        compare: 'under'
        target: 100

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
      restore = argvParser.__set__({
        fs:
          readFileSync: ->
            return JSON.stringify([])
          writeFileSync: ->
        missingArgHandler: ->
        unknownArgvHandler: ->
        illegalValueHandler: ->
      })
      return
    )
    afterEach(-> restore())

    it('should write new verdict when no duplication', ->
      argvParser.__set__({
        fs:
          readFileSync: ->
            return JSON.stringify([])
          writeFileSync: (file, data) ->
            makeCalledTrue()
            data.should.equal(JSON.stringify([fullVerdict]))
            return
      })
      addHandler([
        'id', fullVerdict.id,
        'site', fullVerdict.site,
        'price', fullVerdict.price.compare, fullVerdict.price.target.toString(),
        'discount', fullVerdict.discount.compare, fullVerdict.discount.target.toString(),
        'review', fullVerdict.review.compare, fullVerdict.review.target.toString(),
        'instore', 'yes',
        'benefits', '/20% off/i'
      ])
      called.should.be.true
      return
    )

    it('should make new verdict with unified verdict fields format', ->
      argvParser.__set__({
        fs:
          readFileSync: ->
            return JSON.stringify([])
          writeFileSync: (file, data) ->
            makeCalledTrue()
            argvParser.__get__('AVAILABLE_VERDICT_FIELDS').map((field) ->
              product = JSON.parse(data).pop()
              product.should.have.property(field)
              product[field].should.have.property('compare')
              product[field].should.have.property('target')
              return
            )
            return
      })
      addHandler([
        'id', fullVerdict.id,
        'site', fullVerdict.site,
        'price', fullVerdict.price.compare, fullVerdict.price.target.toString(),
        'discount', fullVerdict.discount.compare, fullVerdict.discount.target.toString(),
        'review', fullVerdict.review.compare, fullVerdict.review.target.toString(),
        'instore', 'yes',
        'benefits', '/20% off/i'
      ])
      called.should.be.true
      return
    )

    it('should overwrite verdict when both id and site matched', ->
      argvParser.__set__({
        fs:
          readFileSync: ->
            return JSON.stringify([simpleVerdict])
          writeFileSync: (file, data) ->
            makeCalledTrue()
            data.should.equal(JSON.stringify([fullVerdict]))
            return
      })
      addHandler([
        'id', fullVerdict.id,
        'site', fullVerdict.site,
        'price', fullVerdict.price.compare, fullVerdict.price.target.toString(),
        'discount', fullVerdict.discount.compare, fullVerdict.discount.target.toString(),
        'review', fullVerdict.review.compare, fullVerdict.review.target.toString(),
        'instore', 'yes',
        'benefits', '/20% off/i'
      ])
      called.should.be.true
      return
    )

    it('should make result no depence on from keywords sequence', ->
      writeData = writeDataA = writeDataB = null
      argvParser.__set__({
        fs:
          readFileSync: ->
            return JSON.stringify([])
          writeFileSync: (file, data) ->
            makeCalledTrue()
            writeData = JSON.parse(data)
            return
      })
      addHandler([
        'id', simpleVerdict.id,
        'site', simpleVerdict.site,
        'price', simpleVerdict.price.compare, simpleVerdict.price.target
      ])
      writeDataA = writeData
      addHandler([
        'site', simpleVerdict.site,
        'price', simpleVerdict.price.compare, simpleVerdict.price.target
        'id', simpleVerdict.id,
      ])
      writeDataB = writeData

      writeDataA.should.eql(writeDataB)
      called.should.be.true
      return
    )

    it('should route to missing arg handler when id not given', ->
      argvParser.__set__('missingArgHandler', makeCalledTrue)
      addHandler([
        'site', simpleVerdict,
        'price', simpleVerdict.price.compare, simpleVerdict.price.target
      ])
      called.should.be.true
      return
    )

    it('should route to missing arg handler when site not given', ->
      argvParser.__set__('missingArgHandler', makeCalledTrue)
      addHandler([
        'id', simpleVerdict.id,
        'price', simpleVerdict.price.compare, simpleVerdict.price.target])
      called.should.be.true
      return
    )

    it('should route to missing arg handler when non verdicts given', ->
      argvParser.__set__('missingArgHandler', makeCalledTrue)
      addHandler([
        'id', simpleVerdict.id,
        'site', simpleVerdict.site])
      called.should.be.true
      return
    )

    it('should route to missing arg handler when verdict field not given', ->
      argvParser.__set__('missingArgHandler', makeCalledTrue)
      addHandler(['id'])
      called.should.be.true
      makeCalledFalse()
      addHandler([
        'id', simpleVerdict.id,
        'site', simpleVerdict.site,
        'price'])
      called.should.be.true
      makeCalledFalse()
      addHandler([
        'id', simpleVerdict.id,
        'site', simpleVerdict.site,
        'price', simpleVerdict.price.compare])
      called.should.be.true
      makeCalledFalse()
      addHandler([
        'id', simpleVerdict.id,
        'site', simpleVerdict.site,
        'benefits'])
      called.should.be.true
      return
    )

    it('should route to unknown argv handler when verdict unknown', ->
      argvParser.__set__('unknownArgvHandler', makeCalledTrue)
      addHandler([
        'id', simpleVerdict.id,
        'site', simpleVerdict.site,
        'foo'])
      called.should.be.true
      makeCalledFalse()
      addHandler([
        'foo',
        'id', simpleVerdict.id,
        'site', simpleVerdict.site])
      called.should.be.true
      return
    )

    it('should route to unknown argv handler when verdict field unknown', ->
      argvParser.__set__('unknownArgvHandler', makeCalledTrue)
      addHandler([
        'id', simpleVerdict.id,
        'site', simpleVerdict.site,
        'price', 'foo', simpleVerdict.price.target
      ])
      called.should.be.true
      return
    )

    it('should route to illegal value handler when id value illegal', ->
      argvParser.__set__('illegalValueHandler', makeCalledTrue)
      addHandler([
        'id', 'notvalidis...',
        'site', simpleVerdict.site,
        'price', simpleVerdict.price.compare, simpleVerdict.price.target
      ])
      called.should.be.true
      return
    )

    it('should route to illegal value handler when site value illegal', ->
      argvParser.__set__('illegalValueHandler', makeCalledTrue)
      addHandler([
        'id', simpleVerdict.id,
        'site', 'www.example.com,cn',
        'price', simpleVerdict.price.compare, simpleVerdict.price.target
      ])
      called.should.be.true
      return
    )
    return
  )

  describe('remove handler', ->
    removeHandler = argvParser.__get__('removeHandler')
    simpleVerdict =
      id: 'test0000'
      site: 'www.example.com'
      price:
        compare: 'under'
        target: 100

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
      restore = argvParser.__set__({
        fs:
          readFileSync: ->
            return JSON.stringify([simpleVerdict])
          writeFileSync: ->
        verdictNotFoundHandler: ->
        missingArgHandler: ->
        unknownArgvHandler: ->
      })
      return
    )
    afterEach(-> restore())
    
    it('should remove verdict when both id and site matched', ->
      argvParser.__set__({
        fs:
          readFileSync: ->
            return JSON.stringify([simpleVerdict])
          writeFileSync: (file, data) ->
            makeCalledTrue()
            data.should.equal(JSON.stringify([]))
            return
      })
      removeHandler(['id', simpleVerdict.id, 'site', simpleVerdict.site])
      called.should.be.true
      return
    )
    
    it('should make result no depence on keywords sequence', ->
      writeData = writeDataA = writeDataB = null
      argvParser.__set__({
        fs:
          readFileSync: ->
            return JSON.stringify([simpleVerdict])
          writeFileSync: (file, data) ->
            makeCalledTrue()
            data.should.equal(JSON.stringify([]))
            return
      })
      removeHandler(['id', simpleVerdict.id, 'site', simpleVerdict.site])
      called.should.be.true
      removeHandler(['site', simpleVerdict.site, 'id', simpleVerdict.id])
      called.should.be.true
      return
    )

    it('should route to not found handler when given id and site not match', ->
      argvParser.__set__('verdictNotFoundHandler', makeCalledTrue)
      removeHandler(['id', 'foo', 'site', simpleVerdict.site])
      called.should.be.true
      makeCalledFalse()
      removeHandler(['id', simpleVerdict.id, 'site', 'www.foobar.com'])
      called.should.be.true
      makeCalledFalse()
      removeHandler(['id', 'foo', 'site', 'www.foobar.com'])
      called.should.be.true
      return
    )

    it('should route to missing arg handler when id or site value not given', ->
      argvParser.__set__('missingArgHandler', makeCalledTrue)
      removeHandler(['id'])
      called.should.be.true
      makeCalledFalse()
      removeHandler(['id', simpleVerdict.id, 'site'])
      called.should.be.true
      makeCalledFalse()
      removeHandler(['site', 'id', simpleVerdict.id])
      called.should.be.true
      makeCalledFalse()
      removeHandler(['id', 'site', simpleVerdict.site])
      called.should.be.true
      makeCalledFalse()
      removeHandler(['site', simpleVerdict.site, 'id'])
      called.should.be.true
      return
    )

    it('should route to missing arg handler when id not given', ->
      argvParser.__set__('missingArgHandler', makeCalledTrue)
      removeHandler(['site', simpleVerdict.site])
      called.should.be.true
      return
    )

    it('should route to missing arg handler when site not given', ->
      argvParser.__set__('missingArgHandler', makeCalledTrue)
      removeHandler(['id', simpleVerdict.id])
      called.should.be.true
      return
    )

    it('should route to unknown arg handler when keywords unknown', ->
      argvParser.__set__('unknownArgvHandler', makeCalledTrue)
      removeHandler(['id', simpleVerdict.id, 'foo', 'site', simpleVerdict.site])
      called.should.be.true
      return
    )
    return
  )

  describe('reset handler', ->
    resetHandler = argvParser.__get__('resetHandler')

    writeFileCalled = false
    makeWriteFileCalledTrue = ->
      writeFileCalled = true
      return
    makeWriteFileCalledFalse = ->
      writeFileCalled = false
      return
    userInputDone = false
    makeUserInputDoneTrue = ->
      userInputDone = true
      return
    makeUserInputDoneFalse = ->
      userInputDone = false
      return
    restore = null
    beforeEach(->
      makeWriteFileCalledFalse()
      makeUserInputDoneFalse()
      restore = argvParser.__set__({
        fs:
          writeFileSync: makeWriteFileCalledTrue
        process:
          stdin:
            setEncoding: ->
            once: (ev, callback) ->
              makeUserInputDoneTrue()
              ev == 'data' and callback('yes')
              return
          stdout:
            write: ->
        invalidResponseHandler: ->
      })
      return
    )
    afterEach(-> restore())

    it('should clear verdicts record when user approve reset', ->
      argvParser.__set__({
        fs:
          writeFileSync: (file, data) ->
            makeWriteFileCalledTrue()
            data.should.equal(JSON.stringify([]))
            return
      })
      resetHandler()
      writeFileCalled.should.be.true
      userInputDone.should.be.true
      return
    )

    it('should not clear verdicts record when user not approve reset', ->
      argvParser.__set__({
        process:
          stdin:
            setEncoding: ->
            once: (ev, callback) ->
              makeUserInputDoneTrue()
              ev == 'data' and callback('no')
              return
          stdout:
            write: ->
      })
      resetHandler()
      writeFileCalled.should.be.false
      userInputDone.should.be.true
      return
    )

    it('should route to invalid response handler when user input invalid', ->
      called = false
      argvParser.__set__({
        process:
          stdin:
            setEncoding: ->
            once: (ev, callback) ->
              makeUserInputDoneTrue()
              ev == 'data' and callback('foo')
              return
          stdout:
            write: ->
        invalidResponseHandler: ->
          called = true
          return
      })
      resetHandler()
      writeFileCalled.should.be.false
      userInputDone.should.be.true
      called.should.be.true
      return
    )
    return
  )

  describe('list handler', ->
    listHandler = argvParser.__get__('listHandler')

    called = false
    makeCalledTrue = ->
      called = true
      return
    makeCalledFalse = ->
      called = false
    restore = null
    beforeEach(->
      makeCalledFalse()
      restore = argvParser.__set__({
        fs:
          readFileSync: ->
            makeCalledTrue()
            return JSON.stringify([])
      })
      return
    )
    afterEach(-> restore())

    it('should read verdicts record', ->
      listHandler()
      called.should.be.true
      return
    )
    return
  )

  describe('help handler', ->)

  describe('verdict not found handler', ->
    verdictNotFoundHandler = argvParser.__get__('verdictNotFoundHandler')
    it('should throw error', ->
      verdictNotFoundHandler.should.throw('input error, verdict not founded')
      return
    )
    return
  )

  describe('unknown argv handler', ->
    unknownArgvHandler = argvParser.__get__('unknownArgvHandler')
    it('should throw error', ->
      unknownArgvHandler.should.throw('input error, unknown arguments')
      return
    )
    return
  )

  describe('missing arg handler', ->
    missingArgHandler = argvParser.__get__('missingArgHandler')
    it('should throw error', ->
      missingArgHandler.should.throw('input error, missing arguments')
      return
    )
    return
  )

  describe('invalid response handler', ->
    invalidResponseHandler = argvParser.__get__('invalidResponseHandler')
    it('should throw error', ->
      invalidResponseHandler.bind(null, 'foo')
        .should.throw('input error, invalid response')
      return
    )
    return
  )

  describe('illegal value handler', ->
    illegalValueHandler = argvParser.__get__('illegalValueHandler')
    it('should throw error', ->
      illegalValueHandler.bind(null, 'foo')
        .should.throw('input error, illegal value')
      return
    )
    return
  )
  return
)
