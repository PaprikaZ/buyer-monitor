stream = require('stream')
rewire = require('rewire')

describe('Argv Parser', ->
  describe('parse', ->
    argvParser = rewire('../lib/argv_parser.js')
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
      argvParser.parse([], makeCalledTrue)
      called.should.be.true
      return
    )

    it('should route to add handler when add followed arguments', ->
      argvParser.__set__('addHandler', makeCalledTrue)
      argvParser.parse(['add', 'foo'], ->)
      called.should.be.true
      return
    )

    it('should route to unknown handler when only add given', ->
      argvParser.parse.bind(null, ['add'], ->)
        .should.throw(mockErrorMsg)
      called.should.be.true
      return
    )

    it('should route to remove handler when remove followed arguments', ->
      argvParser.__set__('removeHandler', makeCalledTrue)
      argvParser.parse(['remove', 'foo'], ->)
      called.should.be.true
      return
    )

    it('should route to unknown handler when only remove given', ->
      argvParser.parse.bind(null, ['remove'], ->)
        .should.throw(mockErrorMsg)
      called.should.be.true
      return
    )

    it('should route to list handler when only list given', ->
      argvParser.__set__('listHandler', makeCalledTrue)
      argvParser.parse(['list'], ->)
      called.should.be.true
      return
    )

    it('should route to unknown handler when list followed arguments', ->
      argvParser.parse.bind(null, ['list', 'foo'], ->)
        .should.throw(mockErrorMsg)
      called.should.be.true
      return
    )

    it('should route to reset handler when only reset given', ->
      argvParser.__set__('resetHandler', makeCalledTrue)
      argvParser.parse(['reset'], ->)
      called.should.be.true
      return
    )

    it('should route to unknown handler when reset followed arguments', ->
      argvParser.parse.bind(null, ['reset', 'foo'], ->)
        .should.throw(mockErrorMsg)
      called.should.be.true
      return
    )

    it('should route to help handler when only help given', ->
      argvParser.__set__('helpHandler', makeCalledTrue)
      argvParser.parse(['help'], ->)
      called.should.be.true
      return
    )

    it('should route to unknown handler when help followed arguments', ->
      argvParser.parse.bind(null, ['help', 'foo'], ->)
        .should.throw(mockErrorMsg)
      called.should.be.true
      return
    )

    it('should route to unknown handler when unknown arguments given', ->
      argvParser.parse.bind(null, ['foo'], ->)
        .should.throw(mockErrorMsg)
      called.should.be.true
      return
    )
    return
  )

  describe('helpHandler', ->
    argvParser = rewire('../lib/argv_parser.js')
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

    it('should call process exit', ->
      revert = argvParser.__set__({
        process:
          exit: makeCalledTrue
      })
      argvParser.__get__('helpHandler')()
      called.should.be.true
      revert()
      return
    )
    return
  )

  describe('unknownArgvHandler', ->
    argvParser = rewire('../lib/argv_parser.js')
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
      argvParser.__get__('unknownArgvHandler')
        .should.throw(/^Unknown arguments/)
      return
    )
    return
  )

  describe('lackArgHandler', ->
    argvParser = rewire('../lib/argv_parser.js')
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
      argvParser.__get__('lackArgHandler')
        .should.throw(/^Lack of arguments/)
        return
    )
    return
  )

  describe('listHandler', ->
    argvParser = rewire('../lib/argv_parser.js')
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

    it('should call process exit', ->
      revert = argvParser.__set__({
        process:
          exit: makeCalledTrue
      })
      argvParser.__get__('listHandler')()
      called.should.be.true
      revert()
      return
    )
    return
  )

  describe('addHandler', ->
    argvParser = rewire('../lib/argv_parser.js')
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

    it('should call process exit with id, site, and require', ->
      argvParser.__set__({
        process:
          exit: makeCalledTrue
      })
      argvParser.__get__('addHandler')(['id', 'test0001', 'site', 'www.example.com', 'price', 'under', '0'])
      called.should.be.true
      return
    )

    it('should call lack argv handler without id argument', ->
      revert = argvParser.__set__({
        lackArgHandler: ->
          makeCalledTrue()
          throwMockError()
          return
      })
      argvParser.__get__('addHandler').bind(null, ['site', 'www.example.com', 'price', 'under', '0'])
        .should.throw(mockErrorMsg)
      called.should.be.true
      revert()
      return
    )

    it('should call lack argv handler without site argument', ->
      revert = argvParser.__set__({
        lackArgHandler: ->
          makeCalledTrue()
          throwMockError()
          return
      })
      argvParser.__get__('addHandler').bind(null, ['id', 'test0000', 'price', 'under', '0'])
        .should.throw(mockErrorMsg)
      called.should.be.true
      revert()
      return
    )

    it('should call lack argv handler without require arguments', ->
      revert = argvParser.__set__({
        lackArgHandler: ->
          makeCalledTrue()
          throwMockError()
          return
      })
      argvParser.__get__('addHandler').bind(null, ['id', 'test0000', 'site', 'www.example.com'])
        .should.throw(mockErrorMsg)
      called.should.be.true
      revert()
      return
    )

    it('should call lack argv handler when keyword field not given', ->
      revert = argvParser.__set__({
        lackArgHandler: ->
          makeCalledTrue()
          throwMockError()
          return
      })
      argvParser.__get__('addHandler').bind(null, ['id'])
        .should.throw(mockErrorMsg)
      argvParser.__get__('addHandler').bind(null, ['id', 'test0000', 'site', 'www.example.com', 'price'])
        .should.throw(mockErrorMsg)
      argvParser.__get__('addHandler').bind(null, ['id', 'test0000', 'site', 'www.example.com', 'price', 'under'])
        .should.throw(mockErrorMsg)
      argvParser.__get__('addHandler').bind(null, ['id', 'test0000', 'site', 'www.example.com', 'benefit'])
        .should.throw(mockErrorMsg)
      called.should.be.true
      revert()
      return
    )

    it('should call unknown argv handler with unknown arguments', ->
      revert = argvParser.__set__({
        unknownArgvHandler: ->
          makeCalledTrue()
          throwMockError()
          return
      })
      argvParser.__get__('addHandler').bind(null, 'id', 'test0000', 'site', 'www.example.com', 'foo')
        .should.throw(mockErrorMsg)
      called.should.be.true
      revert()
      return
    )

    it('should write new record to product data file', ->
      argvParser.__set__({
        fs:
          readFileSync: ->
            return JSON.stringify([])
          writeFileSync: (file, data) ->
            data.should.equal(JSON.stringify([defaultProduct]))
            return
      })
      argvParser.__get__('addHandler')(['id', defaultProduct.id, 'site', defaultProduct.site, 'price', defaultProduct.price.compare, defaultProduct.price.target])
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
      argvParser.__get__('addHandler')(['id', defaultProduct.id, 'site', defaultProduct.site, 'price', defaultProduct.price.compare, newProduct.price.target])
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
      argvParser.__get__('addHandler')(['id', defaultProduct.id, 'site', defaultProduct.site, 'price', defaultProduct.price.compare, newProduct.price.target])
      return
    )
    return
  )

  describe('removeHandler', ->
    argvParser = rewire('../lib/argv_parser.js')
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

    it('should call process exit with only id specified', ->
      argvParser.__set__({
        process:
          exit: makeCalledTrue
      })
      argvParser.__get__('removeHandler')(['id', defaultProduct.id])
      called.should.be.true
      return
    )

    it('should call process exit with both id, site specified', ->
      argvParser.__set__({
        process:
          exit: makeCalledTrue
      })
      argvParser.__get__('removeHandler')(['id', defaultProduct.id, 'site', defaultProduct.site])
      called.should.be.true
      return
    )

    it('should call lack arg handler when id or site field not given', ->
      revert = argvParser.__set__({
        lackArgHandler: ->
          makeCalledTrue()
          throwMockError()
          return
      })
      argvParser.__get__('removeHandler').bind(null, ['id'])
        .should.throw(mockErrorMsg)
      argvParser.__get__('removeHandler').bind(null, ['id', 'test0000', 'site'])
        .should.throw(mockErrorMsg)
      called.should.be.true
      revert()
      return
    )

    it('should call lack arg handler without id specified', ->
      revert = argvParser.__set__({
        lackArgHandler: ->
          makeCalledTrue()
          throwMockError()
          return
      })
      argvParser.__get__('removeHandler').bind(null, ['site', 'www.example.com'])
        .should.throw(mockErrorMsg)
      called.should.be.true
      revert()
      return
    )

    it('should call unknown arg handler with unknown arguments', ->
      revert = argvParser.__set__({
        unknownArgvHandler: ->
          makeCalledTrue()
          throwMockError()
          return
      })
      argvParser.__get__('removeHandler').bind(null, ['id', 'test0000', 'foo', 'site', 'www.example.com'])
        .should.throw(mockErrorMsg)
      called.should.be.true
      revert()
      return
    )

    it('should remove record with id specified when site not given', ->
      argvParser.__set__({
        fs:
          readFileSync: ->
            return JSON.stringify([defaultProduct])
          writeFileSync: (file, data) ->
            data.should.equal(JSON.stringify([]))
            return
      })
      argvParser.__get__('removeHandler')(['id', defaultProduct.id])
      return
    )
    
    it('should remove record with both id and site specified', ->
      argvParser.__set__({
        fs:
          readFileSync: ->
            return JSON.stringify([defaultProduct])
          writeFileSync: (file, data) ->
            data.should.equal(JSON.stringify([]))
            return
      })
      argvParser.__get__('removeHandler')(['id', defaultProduct.id, 'site', defaultProduct.site])
      return
    )

    it('should throw not found error when id or site not existed', ->
      argvParser.__set__({
        fs:
          readFileSync: ->
            return JSON.stringify([defaultProduct])
          writeFileSync: ->
      })
      argvParser.__get__('removeHandler').bind(null, ['id', 'notexistid', 'site', 'www.example.com'])
        .should.throw(/not founded!$/)
      argvParser.__get__('removeHandler').bind(null, ['id', defaultProduct.id, 'site', 'www.notexist.com'])
        .should.throw(/not founded!$/)
      return
    )

    it('should throw not found error when specific id not existed', ->
      argvParser.__set__({
        fs:
          readFileSync: ->
            return JSON.stringify([defaultProduct])
          writeFileSync: ->
      })
      argvParser.__get__('removeHandler').bind(null, ['id', 'notexistid'])
        .should.throw(/not founded!$/)
      return
    )
    return
  )

  describe('resetHandler', ->
    argvParser = rewire('../lib/argv_parser.js')
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

    it('should call process exit when user approve reset', ->
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
      argvParser.__get__('resetHandler')()
      called.should.be.true
      return
    )

    it('should call process exit when user not approve reset', ->
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
      argvParser.__get__('resetHandler')()
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
      argvParser.__get__('resetHandler').should.throw(/^Invalid response/)
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
      argvParser.__get__('resetHandler')()
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
      argvParser.__get__('resetHandler')()
      writeFileCalled.should.be.false
      called.should.be.true
      return
    )
    return
  )
  return
)
