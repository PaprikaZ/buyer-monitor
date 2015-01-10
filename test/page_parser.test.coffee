util = require('util')
fs = require('fs')
rewire = require('rewire')

describe('page parser module', ->
  urlToHtmlTable = require('./cache/html.json')
  pageParser = rewire('../lib/page_parser.js')
  createParser = pageParser.createParser
  pageParser.__set__({
    logger:
      debug: ->
      info: ->
      warn: ->
      error: ->
  })

  describe('site selector', ->

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
      restore = pageParser.__set__({
        invalidSiteHandler: ->
      })
      return
    )
    afterEach(-> restore())

    it('should select amazon cn parser when given www.amazon.cn', ->
      AmazonCNParser = pageParser.__get__('AmazonCNParser')
      createParser('www.amazon.cn').should.be.a.AmazonCNParser
      return
    )

    it('should select amazon us parser when given www.amazon.com', ->
      AmazonUSParser = pageParser.__get__('AmazonUSParser')
      createParser('www.amazon.com').should.be.a.AmazonUSParser
      return
    )

    it('should select amazon jp parser when given www.amazon.co.jp', ->
      AmazonJPParser = pageParser.__get__('AmazonJPParser')
      createParser('www.amazon.co.jp').should.be.a.AmazonJPParser
      return
    )

    it('should select jingdong parser when given www.jd.com', ->
      JingdongParser = pageParser.__get__('JingdongParser')
      createParser('www.jd.com').should.be.a.JingdongParser
      return
    )

    it('should route to invalid site handler when neither above sites given', ->
      pageParser.__set__('invalidSiteHandler', makeCalledTrue)
      createParser('foo')
      called.should.be.true
      return
    )
    return
  )

  Parser = pageParser.__get__('Parser')
  MANDATORY_OUTPUT_FIELDS = pageParser.MANDATORY_OUTPUT_FIELDS
  _MANDATORY_PARSE_FIELDS = pageParser.__get__('_MANDATORY_PARSE_FIELDS')

  createSiteDescribe = (title, siteRegExp, site) ->
    describe(title, ->
      table = {}
      for url, file of urlToHtmlTable
        if siteRegExp.test(url)
          table[url] = file

      if 0 < Object.getOwnPropertyNames(table).length
        defaultParser = new Parser()
        siteParser = createParser(site)

        for url, file of table
          behavior = util.format('should parse %s as expect', url)
          html = fs.readFileSync(file, {encoding: 'utf8'})

          it(behavior, ((html) ->
            return ->
              result = siteParser.parse(html)

              MANDATORY_OUTPUT_FIELDS.map((field) ->
                result.should.have.property(field)
                return
              )
              _MANDATORY_PARSE_FIELDS.map((field) ->
                defaultValue = defaultParser[field]()
                siteValue = result[field]
                siteValue.should.not.equal(defaultValue)
                return
              )
              return
            )(html)
          )
      else
        it('should parse all predefined cached pages as expect')
      return
    )
    return

  createSiteDescribe('amazon cn parser', /amazon\.cn/, 'www.amazon.cn')
  createSiteDescribe('amazon us parser', /amazon\.com/, 'www.amazon.com')
  createSiteDescribe('amazon jp parser', /amazon\.co\.jp/, 'www.amazon.co.jp')
  createSiteDescribe('jingdong parser', /jd\.com/, 'www.jd.com')

  describe('amazon cn parser parse', ->
    it('should treat full price zero when it is not available')
    return
  )

  describe('parse error handler', ->
    parseErrorHandler = pageParser.__get__('parseErrorHandler')
    it('should throw error', ->
      parseErrorHandler.bind(null, 'testParser').should.throw('parse error')
      return
    )
    return
  )

  describe('invalid site handler', ->
    invalidSiteHandler = pageParser.__get__('invalidSiteHandler')
    it('should throw error', ->
      invalidSiteHandler.bind(null, 'foo')
        .should.throw('invalid data error, no available parser for invalid site')
      return
    )
    return
  )
  return
)
