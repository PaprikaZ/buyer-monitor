util = require('util')
rewire = require('rewire')

describe('site module', ->
  site = rewire('../lib/site.js')
  unknownSite = 'www.example.com'
  testId = 'testid0000'

  describe('generate product url', ->
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
      restore = site.__set__({
        siteNotSupportHandler: ->
      })
      return
    )
    afterEach(-> restore())

    it('should generate amazon cn product url', ->
      url = util.format('http://www.amazon.cn/dp/%s', testId)
      site.generateProductUrl(testId, 'www.amazon.cn').should.equal(url)
      return
    )

    it('should generate amazon com product url', ->
      url = util.format('http://www.amazon.com/dp/%s', testId)
      site.generateProductUrl(testId, 'www.amazon.com').should.equal(url)
      return
    )

    it('should generate amazon jp product url', ->
      url = util.format('http://www.amazon.co.jp/dp/%s', testId)
      site.generateProductUrl(testId, 'www.amazon.co.jp').should.equal(url)
      return
    )

    it('should generate jingdong product url', ->
      url = util.format('http://item.jd.com/%s.html', testId)
      site.generateProductUrl(testId, 'www.jd.com').should.equal(url)
      return
    )

    it('should route to site not support handler', ->
      site.__set__('siteNotSupportHandler', makeCalledTrue)
      site.generateProductUrl(testId, unknownSite)
      called.should.be.true
      return
    )
    return
  )

  describe('get site encoding', ->
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
      restore = site.__set__({
        siteNotSupportHandler: ->
      })
      return
    )
    afterEach(-> restore())

    it('should return utf8 on all amazon sites', ->
      site.getSiteEncoding('www.amazon.cn').should.equal('utf8')
      site.getSiteEncoding('www.amazon.com').should.equal('utf8')
      site.getSiteEncoding('www.amazon.co.jp').should.equal('utf8')
      return
    )
    
    it('should return gbk on jingdong site', ->
      site.getSiteEncoding('www.jd.com').should.equal('gbk')
      return
    )

    it('should route to site not support handler', ->
      site.__set__('siteNotSupportHandler', makeCalledTrue)
      site.getSiteEncoding(unknownSite)
      called.should.be.true
      return
    )
    return
  )

  describe('url to site', ->
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
      restore = site.__set__({
        siteNotSupportHandler: ->
      })
      return
    )
    afterEach(-> restore())

    it('should return amazon cn site url', ->
      site.urlToSite('www.amazon.cn').should.equal('www.amazon.cn')
      site.urlToSite('www.amazon.cn/dp/foo').should.equal('www.amazon.cn')
      return
    )

    it('should return amazon com site url', ->
      site.urlToSite('www.amazon.com').should.equal('www.amazon.com')
      site.urlToSite('www.amazon.com/dp/foo').should.equal('www.amazon.com')
      return
    )

    it('should return amazon jp site url', ->
      site.urlToSite('www.amazon.co.jp').should.equal('www.amazon.co.jp')
      site.urlToSite('www.amazon.co.jp/dp/bar').should.equal('www.amazon.co.jp')
      return
    )

    it('should return jingdong site url', ->
      site.urlToSite('www.jd.com').should.equal('www.jd.com')
      site.urlToSite('item.jd.com/example.html').should.equal('www.jd.com')
      return
    )

    it('should route to url not support handler', ->
      site.__set__('urlNotSupportHandler', makeCalledTrue)
      site.urlToSite(unknownSite)
      called.should.be.true
      return
    )
    return
  )
  return
)
