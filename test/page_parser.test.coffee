util = require('util')
path = require('path')
fs = require('fs')
rewire = require('rewire')
pageParser = rewire('../lib/page_parser.js')
cacheDir = './cache'
urlToHtmlTable = require('./cache/html.json')

describe('page parser', ->
  pageParser.__set__({
    logger:
      debug: ->
      info: ->
      warn: ->
      error: ->
  })
  Parser = pageParser.__get__('Parser')
  _MANDATORY_PARSE_FIELDS = pageParser.__get__('_MANDATORY_PARSE_FIELDS')
  MANDATORY_FIELDS = pageParser.__get__('MANDATORY_FIELDS')

  describe('site selector', ->
    createParser = pageParser.createParser

    it('should select amazon cn parser when given www.amazon.cn', ->
      AmazonCNParser = pageParser.__get__('AmazonCNParser')
      parser = createParser('www.amazon.cn')
      parser.should.be.a.AmazonCNParser
      return
    )

    it('should select amazon us parser when given www.amazon.com', ->
      AmazonUSParser = pageParser.__get__('AmazonUSParser')
      parser = createParser('www.amazon.com')
      parser.should.be.a.AmazonUSParser
      return
    )

    it('should select amazon jp parser when given www.amazon.co.jp', ->
      AmazonJPParser = pageParser.__get__('AmazonJPParser')
      parser = createParser('www.amazon.co.jp')
      parser.should.be.a.AmazonJPParser
      return
    )

    it('should select jingdong parser when given www.jd.com', ->
      JingdongParser = pageParser.__get__('JingdongParser')
      parser = createParser('www.jd.com')
      parser.should.be.a.JingdongParser
      return
    )

    it('should throw error when neither above site given', ->
      createParser.bind(null, 'foo').should.throw('no available parser')
      return
    )
    return
  )

  createSiteDescribe = (title, siteRegExp, site) ->
    createParser = pageParser.createParser

    describe(title, ->
      table = {}
      for url, file of urlToHtmlTable
        if siteRegExp.test(url)
          table[url] = path.join(cacheDir, file)

      if 0 < Object.getOwnPropertyNames(table).length
        defaultParser = new Parser()
        siteParser = createParser(site)

        for url, file of table
          behavior = util.format('should parse %s as expect', url)
          it(behavior, ->
            html = fs.readFileSync(path.join(__dirname, file))
            result = siteParser.parse(html)

            MANDATORY_FIELDS.map((field) ->
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
          )
      else
        it('should parse all predefined cached pages as expect')
      return
    )
    return

  createSiteDescribe('amazon cn', /amazon\.cn/, 'www.amazon.cn')
  createSiteDescribe('amazon us', /amazon\.com/, 'www.amazon.com')
  createSiteDescribe('amazon jp', /amazon\.co\.jp/, 'www.amazon.co.jp')
  createSiteDescribe('jingdong', /jd\.com/, 'www.jd.com')
  return
)
