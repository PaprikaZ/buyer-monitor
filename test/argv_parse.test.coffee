rewire = require('rewire')

describe('argv parser', ->
  describe('parse', ->
    argvParser = rewire('../lib/argv_parser.js')
    parse = argvParser.parse
    called = false
    makeCalledTrue = ->
      called = true
      return
    makeCalledFalse = ->
      called = false
      return
    mockErrorMsg = 'mock error'
    throwMockError = ->
      throw new Error(mockErrorMsg)
    beforeEach(->
      called = false
      argvParser.__set__({
        addHandler: makeCalledFalse
        removeHandler: makeCalledFalse
        listHandler: makeCalledFalse
        resetHandler: makeCalledFalse
        helpHandler: makeCalledFalse
        unknownArgvHandler: ->
          makeCalledTrue()
          throwMockError()
          return
      })
      return
    )

    it('should route to launch when no further arguments', ->
      parse([], makeCalledTrue)
      called.should.be.true
      return
    )

    it('should route to add handler when add followed arguments', ->
      argvParser.__set__('addHandler', makeCalledTrue)
      parse(['add', 'foo'], ->)
      called.should.be.true
      return
    )

    it('should route to unknown handler when only add given', ->
      parse.bind(null, ['add'], ->).should.throw(mockErrorMsg)
      called.should.be.true
      return
    )

    it('should route to remove handler when remove followed arguments', ->
      argvParser.__set__('removeHandler', makeCalledTrue)
      parse(['remove', 'foo'], ->)
      called.should.be.true
      return
    )

    it('should route to unknown handler when only remove given', ->
      parse.bind(null, ['remove'], ->).should.throw(mockErrorMsg)
      called.should.be.true
      return
    )

    it('should route to list handler when only list given', ->
      argvParser.__set__('listHandler', makeCalledTrue)
      parse(['list'], ->)
      called.should.be.true
      return
    )

    it('should route to unknown handler when list followed arguments', ->
      parse.bind(null, ['list', 'foo'], ->).should.throw(mockErrorMsg)
      called.should.be.true
      return
    )

    it('should route to reset handler when only reset given', ->
      argvParser.__set__('resetHandler', makeCalledTrue)
      parse(['reset'], ->)
      called.should.be.true
      return
    )

    it('should route to unknown handler when reset followed arguments', ->
      parse.bind(null, ['reset', 'foo'], ->).should.throw(mockErrorMsg)
      called.should.be.true
      return
    )

    it('should route to help handler when only help given', ->
      argvParser.__set__('helpHandler', makeCalledTrue)
      parse(['help'], ->)
      called.should.be.true
      return
    )

    it('should route to unknown handler when help followed arguments', ->
      parse.bind(null, ['help', 'foo'], ->).should.throw(mockErrorMsg)
      called.should.be.true
      return
    )

    it('should route to unknown handler when unknown arguments given', ->
      parse.bind(null, ['foo'], ->).should.throw(mockErrorMsg)
      called.should.be.true
      return
    )
    return
  )

  describe('help handler', ->
    argvParser = rewire('../lib/argv_parser.js')
    helpHandler = argvParser.__get__('helpHandler')
    called = false
    makeCalledTrue = ->
      called = true
      return
    beforeEach(->
      called = false
      argvParser.__set__({
        console:
          log: ->
        process:
          exit: ->
      })
      return
    )

    it('should end with process exit', ->
      revert = argvParser.__set__({
        process:
          exit: makeCalledTrue
      })
      helpHandler()
      called.should.be.true
      revert()
      return
    )
    return
  )

  describe('unknown argv handler', ->
    argvParser = rewire('../lib/argv_parser.js')
    unknownArgvHandler = argvParser.__get__('unknownArgvHandler')
    called = false
    makeCalledTrue = ->
      called = true
      return
    beforeEach(->
      called = false
      argvParser.__set__({
        console:
          log: ->
      })
      return
    )

    it('should throw unknown arguments error', ->
      unknownArgvHandler.should.throw(/^Unknown arguments/)
      return
    )
    return
  )

  describe('lack arg handler', ->
    argvParser = rewire('../lib/argv_parser.js')
    lackArgHandler = argvParser.__get__('lackArgHandler')
    called = false
    makeCalledTrue = ->
      called = true
      return
    beforeEach(->
      called = false
      argvParser.__set__({
        console:
          log: ->
      })
      return
    )

    it('should throw lack of arguments error', ->
      lackArgHandler.should.throw(/^Lack of arguments/)
      return
    )
    return
  )

  describe('list handler', ->
    argvParser = rewire('../lib/argv_parser.js')
    listHandler = argvParser.__get__('listHandler')
    called = false
    makeCalledTrue = ->
      called = true
      return
    beforeEach(->
      called = false
      argvParser.__set__({
        console:
          log: ->
        process:
          exit: ->
        fs:
          readFileSync: ->
            return JSON.stringify([])
      })
      return
    )

    it('should end with process exit', ->
      revert = argvParser.__set__({
        process:
          exit: makeCalledTrue
      })
      listHandler()
      called.should.be.true
      revert()
      return
    )
    return
  )

  describe('add handler', ->
    argvParser = rewire('../lib/argv_parser.js')
    addHandler = argvParser.__get__('addHandler')
    called = false
    makeCalledTrue = ->
      called = true
      return
    mockErrorMsg = 'mock error'
    throwMockError = ->
      throw new Error(mockErrorMsg)
    fullVerdictProduct =
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
      benefit:
        compare: 'match'
        target:
          regex: '20% off'
          option: 'i'
    defaultProduct =
      id: 'test0000'
      site: 'www.example.com'
      price:
        compare: 'under'
        target: 100
    newProduct =
      id: 'test0000'
      site: 'www.example.com'
      price:
        compare: 'under'
        target: 110
    beforeEach(->
      called = false
      argvParser.__set__({
        console:
          log: ->
        process:
          exit: ->
        fs:
          writeFileSync: ->
          readFileSync: ->
            return JSON.stringify([])
      })
      return
    )

    it('should end with process exit when id, site, and verdict given', ->
      argvParser.__set__({
        process:
          exit: makeCalledTrue
      })
      addHandler(['id', 'test0001', 'site', 'www.example.com', 'price', 'under', '0'])
      called.should.be.true
      return
    )

    it('should route to lack arg handler when id not given', ->
      revert = argvParser.__set__({
        lackArgHandler: ->
          makeCalledTrue()
          throwMockError()
          return
      })
      addHandler.bind(null, ['site', 'www.example.com', 'price', 'under', '0'])
        .should.throw(mockErrorMsg)
      called.should.be.true
      revert()
      return
    )

    it('should route to lack arg handler when site not given', ->
      revert = argvParser.__set__({
        lackArgHandler: ->
          makeCalledTrue()
          throwMockError()
          return
      })
      addHandler.bind(null, ['id', 'test0000', 'price', 'under', '0'])
        .should.throw(mockErrorMsg)
      called.should.be.true
      revert()
      return
    )

    it('should route to lack arg handler when verdict not given', ->
      revert = argvParser.__set__({
        lackArgHandler: ->
          makeCalledTrue()
          throwMockError()
          return
      })
      addHandler.bind(null, ['id', 'test0000', 'site', 'www.example.com'])
        .should.throw(mockErrorMsg)
      called.should.be.true
      revert()
      return
    )

    it('should route to lack arg handler when keyword field not given', ->
      revert = argvParser.__set__({
        lackArgHandler: ->
          makeCalledTrue()
          throwMockError()
          return
      })
      addHandler.bind(null, ['id']).should.throw(mockErrorMsg)
      addHandler.bind(null, ['id', 'test0000', 'site', 'www.example.com', 'price'])
        .should.throw(mockErrorMsg)
      addHandler.bind(null, ['id', 'test0000', 'site', 'www.example.com', 'price', 'under'])
        .should.throw(mockErrorMsg)
      addHandler.bind(null, ['id', 'test0000', 'site', 'www.example.com', 'benefit'])
        .should.throw(mockErrorMsg)
      called.should.be.true
      revert()
      return
    )

    it('should route to unknown argv handler when meet unknown argument', ->
      revert = argvParser.__set__({
        unknownArgvHandler: ->
          makeCalledTrue()
          throwMockError()
          return
      })
      addHandler.bind(null, 'id', 'test0000', 'site', 'www.example.com', 'foo')
        .should.throw(mockErrorMsg)
      called.should.be.true
      revert()
      return
    )

    it('should write new record when no duplicated record founded', ->
      argvParser.__set__({
        fs:
          readFileSync: ->
            return JSON.stringify([])
          writeFileSync: (file, data) ->
            data.should.equal(JSON.stringify([fullVerdictProduct]))
            return
      })
      addHandler([
        'id', fullVerdictProduct.id,
        'site', fullVerdictProduct.site,
        'price', fullVerdictProduct.price.compare, fullVerdictProduct.price.target.toString(),
        'discount', fullVerdictProduct.discount.compare, fullVerdictProduct.discount.target.toString(),
        'review', fullVerdictProduct.review.compare, fullVerdictProduct.review.target.toString(),
        'instore', 'yes',
        'benefit', '/20% off/i'
      ])
      return
    )

    it('should write new record which have unified verdict data', ->
      argvParser.__set__({
        fs:
          readFileSync: ->
            return JSON.stringify([])
          writeFileSync: (file, data) ->
            argvParser.__get__('MANDATORY_VERDICT_FIELDS').map((field) ->
              product = JSON.parse(data).pop()
              product.should.have.property(field)
              product[field].should.have.property('compare')
              product[field].should.have.property('target')
              return
            )
            return
      })
      addHandler([
        'id', fullVerdictProduct.id,
        'site', fullVerdictProduct.site,
        'price', fullVerdictProduct.price.compare, fullVerdictProduct.price.target.toString(),
        'discount', fullVerdictProduct.discount.compare, fullVerdictProduct.discount.target.toString(),
        'review', fullVerdictProduct.review.compare, fullVerdictProduct.review.target.toString(),
        'instore', 'yes',
        'benefit', '/20% off/i'
      ])
      return
    )

    it('should overwrite record when id, site matched', ->
      argvParser.__set__({
        fs:
          readFileSync: ->
            return JSON.stringify([defaultProduct])
          writeFileSync: (file, data) ->
            data.should.equal(JSON.stringify([newProduct]))
            return
      })
      addHandler([
        'id', defaultProduct.id,
        'site', defaultProduct.site,
        'price', defaultProduct.price.compare, newProduct.price.target.toString()
      ])
      return
    )

    it('should overwrite record when only id given and matched', ->
      argvParser.__set__({
        fs:
          readFileSync: ->
            return JSON.stringify([defaultProduct])
          writeFileSync: (file, data) ->
            data.should.equal(JSON.stringify([newProduct]))
            return
      })
      addHandler([
        'id', defaultProduct.id,
        'site', defaultProduct.site,
        'price', defaultProduct.price.compare, newProduct.price.target.toString()
      ])
      return
    )
    return
  )

  describe('remove handler', ->
    argvParser = rewire('../lib/argv_parser.js')
    removeHandler = argvParser.__get__('removeHandler')
    called = false
    makeCalledTrue = ->
      called = true
      return
    mockErrorMsg = 'mock error'
    throwMockError = ->
      throw new Error(mockErrorMsg)
    defaultProduct =
      id: 'test0000'
      site: 'www.example.com'
    beforeEach(->
      called = false
      argvParser.__set__({
        console:
          log: ->
        process:
          exit: ->
        fs:
          writeFileSync: ->
          readFileSync: ->
            return JSON.stringify([defaultProduct])
      })
      return
    )

    it('should end with process exit when only id given', ->
      argvParser.__set__({
        process:
          exit: makeCalledTrue
      })
      removeHandler(['id', defaultProduct.id])
      called.should.be.true
      return
    )

    it('should end with process exit when both id, site given', ->
      argvParser.__set__({
        process:
          exit: makeCalledTrue
      })
      removeHandler(['id', defaultProduct.id, 'site', defaultProduct.site])
      called.should.be.true
      return
    )

    it('should route to lack arg handler when id or site field not given', ->
      revert = argvParser.__set__({
        lackArgHandler: ->
          makeCalledTrue()
          throwMockError()
          return
      })
      removeHandler.bind(null, ['id']).should.throw(mockErrorMsg)
      removeHandler.bind(null, ['id', 'test0000', 'site']).should.throw(mockErrorMsg)
      called.should.be.true
      revert()
      return
    )

    it('should route to lack arg handler when id not given', ->
      revert = argvParser.__set__({
        lackArgHandler: ->
          makeCalledTrue()
          throwMockError()
          return
      })
      removeHandler.bind(null, ['site', 'www.example.com']).should.throw(mockErrorMsg)
      called.should.be.true
      revert()
      return
    )

    it('should route to unknown arg handler when meet unknown argument', ->
      revert = argvParser.__set__({
        unknownArgvHandler: ->
          makeCalledTrue()
          throwMockError()
          return
      })
      removeHandler.bind(null, ['id', 'test0000', 'foo', 'site', 'www.example.com'])
        .should.throw(mockErrorMsg)
      called.should.be.true
      revert()
      return
    )

    it('should remove record when only id given', ->
      argvParser.__set__({
        fs:
          readFileSync: ->
            return JSON.stringify([defaultProduct])
          writeFileSync: (file, data) ->
            data.should.equal(JSON.stringify([]))
            return
      })
      removeHandler(['id', defaultProduct.id])
      return
    )
    
    it('should remove record when both id and site given', ->
      argvParser.__set__({
        fs:
          readFileSync: ->
            return JSON.stringify([defaultProduct])
          writeFileSync: (file, data) ->
            data.should.equal(JSON.stringify([]))
            return
      })
      removeHandler(['id', defaultProduct.id, 'site', defaultProduct.site])
      return
    )

    it('should throw not found error when id or site not existed', ->
      argvParser.__set__({
        fs:
          readFileSync: ->
            return JSON.stringify([defaultProduct])
          writeFileSync: ->
      })
      removeHandler.bind(null, ['id', 'notexistid', 'site', 'www.example.com'])
        .should.throw(/not founded!$/)
      removeHandler.bind(null, ['id', defaultProduct.id, 'site', 'www.notexist.com'])
        .should.throw(/not founded!$/)
      return
    )

    it('should throw not found error when only given id not existed', ->
      argvParser.__set__({
        fs:
          readFileSync: ->
            return JSON.stringify([defaultProduct])
          writeFileSync: ->
      })
      removeHandler.bind(null, ['id', 'notexistid']).should.throw(/not founded!$/)
      return
    )
    return
  )

  describe('reset handler', ->
    argvParser = rewire('../lib/argv_parser.js')
    resetHandler = argvParser.__get__('resetHandler')
    called = false
    makeCalledTrue = ->
      called = true
      return
    beforeEach(->
      called = false
      argvParser.__set__({
        console:
          log: ->
        fs:
          writeFileSync: ->
        process:
          stdin:
            setEncoding: ->
            once: (ev, callback) ->
              ev == 'data' and callback()
              return
          stdout:
            write: ->
          exit: makeCalledTrue
      })
      return
    )

    it('should end with process exit when user approve reset', ->
      argvParser.__set__({
        fs:
          writeFileSync: ->
        process:
          stdin:
            setEncoding: ->
            once: (ev, callback) ->
              ev == 'data' and callback('yes')
              return
          stdout:
            write: ->
          exit: makeCalledTrue
      })
      resetHandler()
      called.should.be.true
      return
    )

    it('should end with process exit when user not approve reset', ->
      argvParser.__set__({
        process:
          stdin:
            setEncoding: ->
            once: (ev, callback) ->
              ev == 'data' and callback('no')
              return
          stdout:
            write: ->
          exit: makeCalledTrue
      })
      resetHandler()
      called.should.be.true
      return
    )

    it('should throw invalid response error when user input invalid', ->
      argvParser.__set__({
        process:
          stdin:
            setEncoding: ->
            once: (ev, callback) ->
              ev == 'data' and callback('Invalid')
              return
          stdout:
            write: ->
          exit: makeCalledTrue
      })
      resetHandler.should.throw(/^Invalid response/)
      called.should.be.false
      return
    )

    it('should clear all record when user approve it', ->
      argvParser.__set__({
        fs:
          writeFileSync: (file, data) ->
            data.should.equal(JSON.stringify([]))
            return
        process:
          stdin:
            setEncoding: ->
            once: (ev, callback) ->
              ev == 'data' and callback('yes')
              return
          stdout:
            write: ->
          exit: makeCalledTrue
      })
      resetHandler()
      called.should.be.true
      return
    )

    it('should cancel reset operation when user not approve it', ->
      writeFileCalled = false
      argvParser.__set__({
        fs:
          writeFileSync: ->
            writeFileCalled = true
            return
        process:
          stdin:
            setEncoding: ->
            once: (ev, callback) ->
              ev == 'data' and callback('no')
              return
          stdout:
            write: ->
          exit: makeCalledTrue
      })
      resetHandler()
      writeFileCalled.should.be.false
      called.should.be.true
      return
    )
    return
  )
  return
)
