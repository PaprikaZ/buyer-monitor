stream = require('stream')
rewire = require('rewire')

describe('Argv Parser', ->
  describe('parse entry', ->
    argvParser = rewire('../lib/argv_parser.js')
    called = false
    makeCalledTrue = ->
      called = true
      return
    beforeEach(->
      called = false
      argvParser.__set__('addHandler', ->
        called = false
        return
      )
      argvParser.__set__('removeHandler', ->
        called = false
      )
      argvParser.__set__('listHandler', ->
        called = false
      )
      argvParser.__set__('resetHandler', ->
        called = false
      )
      argvParser.__set__('helpHandler', ->
        called = false
      )
      argvParser.__set__('unknownArgvHandler', ->
        called = false
      )
      return
    )
    it('should route to launch entry when no further arguments', ->
      argvParser.parse([], makeCalledTrue)
      called.should.be.true
      return
    )

    it('should route to unknown handler when only add given', ->
      argvParser.__set__('unknownArgvHandler', makeCalledTrue)
      argvParser.parse(['add'], ->)
      called.should.be.true
      return
    )

    it('should route to add handler when add followed arguments', ->
      argvParser.__set__('addHandler', makeCalledTrue)
      argvParser.parse(['add', 'foo'], ->)
      called.should.be.true
      return
    )

    it('should route to unknown handler when only remove given', ->
      argvParser.__set__('unknownArgvHandler', makeCalledTrue)
      argvParser.parse(['remove'], ->)
      called.should.be.true
      return
    )

    it('should route to remove handler when remove followed arguments', ->
      argvParser.__set__('removeHandler', makeCalledTrue)
      argvParser.parse(['remove', 'foo'], ->)
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
      argvParser.__set__('unknownArgvHandler', makeCalledTrue)
      argvParser.parse(['list', 'foo'], ->)
      called.should.be.true
    )

    it('should route to reset handler when only reset given', ->
      argvParser.__set__('resetHandler', makeCalledTrue)
      argvParser.parse(['reset'], ->)
      called.should.be.true
      return
    )

    it('should route to unknown handler when reset followed arguments', ->
      argvParser.__set__('unknownArgvHandler', makeCalledTrue)
      argvParser.parse(['reset', 'foo'], ->)
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
      argvParser.__set__('unknownArgvHandler', makeCalledTrue)
      argvParser.parse(['help', 'foo'], ->)
      called.should.be.true
      return
    )

    it('should route to unknown handler when unknown arguments given', ->
      argvParser.__set__('unknownArgvHandler', makeCalledTrue)
      argvParser.parse(['foo'], ->)
      called.should.be.true
      return
    )
    return
  )
  describe('handler', ->
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
          stdin:
            setEncoding: ->
            once: ->
          stdout:
            write: ->
          exit: makeCalledTrue
        fs:
          writeFileSync: ->
      })
      return
    )

    it("'unknown' should call process exit", ->
      argvParser.__get__('unknownArgvHandler')()
      called.should.be.true
      return
    )

    it("'help' should call process exit", ->
      argvParser.__get__('helpHandler')()
      called.should.be.true
      return
    )

    it("'list' should call process exit", ->
      revert = argvParser.__set__({
        fs:
          readFileSync: (file) ->
            return JSON.stringify([])
      })
      argvParser.__get__('listHandler')()
      called.should.be.true
      revert()
      return
    )

    it("'add' should call process exit with id, site, require specified", ->
      revert = argvParser.__set__({
        fs:
          writeFileSync: ->
          readFileSync: ->
            return JSON.stringify([])
      })
      argvParser.__get__('addHandler')(['id': 'test0001', 'site': 'www.example.com', 'price', 'foo', 'bar'])
      called.should.be.true
      revert()
      return
    )

    it("'remove' should call process exit with id specified", ->
      revert = argvParser.__set__({
        fs:
          writeFileSync: ->
          readFileSync: ->
            return JSON.stringify([])
      })
      argvParser.__get__('removeHandler')(['id', 'test0001'])
      called.should.be.true
      revert()
      return
    )

    it("'remove' should call process exit with both id and site specified", ->
      revert = argvParser.__set__({
        fs:
          writeFileSync: ->
          readFileSync: ->
            return JSON.stringify([])
      })
      argvParser.__get__('removeHandler')(['id', 'test0001', 'site', 'www.example.com'])
      called.should.be.true
      revert()
      return
    )

    it("'reset' should call process exit", ->
      revert = argvParser.__set__({
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
      revert()
      return
    )
    #it("'reset' should call process exit and clear product file", ->
    #  fileWriteCalled = false
    #  revert = argvParser.__set__({
    #    process:
    #      stdin:
    #        setEncoding: ->
    #        once: (ev, callback) ->
    #          ev == 'data' and callback('yes')
    #          return
    #      stdout:
    #        write: ->
    #      exit: makeCalledTrue
    #    fs:
    #      writeFileSync: (file, data)->
    #        if data == JSON.stringify([])
    #          fileWriteCalled = true
    #        return
    #  })
    #  argvParser.__get__('resetHandler')()
    #  called.should.be.true
    #  fileWriteCalled.should.be.true
    #  revert()
    #  return
    #)
      # products = [
      #   {
      #     'id': 'TEST0001',
      #     'site': 'www.example.com',
      #   }
      # ]

    return
  )
  return
)
