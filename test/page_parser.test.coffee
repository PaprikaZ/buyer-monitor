util = require('util')
path = require('path')
rewire = require('rewire')
pageParser = rewire('../lib/page_parser.js')
cacheDir = './cache'
urlToHtmlTable = require('./cache/html.json')

describe('page parser', ->
  describe('site selector', ->
    it('should select amazon cn parser when given www.amazon.cn')
    it('should select amazon us parser when given www.amazon.com')
    it('should select amazon jp parser when given www.amazon.co.jp')
    it('should select jingdong parser when given www.jd.com')
    it('should throw error when neither above site given')
    return
  )

  describe('parse', ->
    it('should deliver result with all mandatory fields')
    return
  )

  createSiteDescribe = (title, siteRegExp) ->
    describe(title, ->
      table = {}
      for url, file of urlToHtmlTable
        if siteRegExp.test(url)
          table[url] = path.join(cacheDir, file)

      if 0 < Object.getOwnPropertyNames(table).length
        for url, file of table
          behavior = util.format('should parse %s as expect', url)
          it(behavior)
      else
        it('should parse all predefined cached pages as expect')
      return
    )
    return

  createSiteDescribe('amazon cn', /amazon\.cn/)
  createSiteDescribe('amazon us', /amazon\.com/)
  createSiteDescribe('amazon jp', /amazon\.co\.jp/)
  createSiteDescribe('jingdong', /jd\.com/)
  return
)
