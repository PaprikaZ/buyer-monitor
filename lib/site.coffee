config = require('./config.js')

httpPrefix = 'http://'
httpsPrefix = 'https://'
htmlSuffix = '.html'

sites = [
  {
    site: 'www.amazon.cn'
    currency: 'CNY'
    encoding: 'utf8'
    regexp: /amazon\.cn/
    generateProductUrl: (productId) ->
      return httpPrefix + @site + '/dp/' + productId
  },
  {
    site: 'www.amazon.com'
    currency: 'USD'
    encoding: 'utf8'
    regexp: /amazon\.com/
    generateProductUrl: (productId) ->
      return httpPrefix + @site + '/dp/' + productId
  },
  {
    site: 'www.amazon.co.jp'
    currency: 'JPY'
    encoding: 'utf8'
    regexp: /amazon\.co\.jp/
    generateProductUrl: (productId) ->
      return httpPrefix + @site + '/dp/' + productId
  },
  {
    site: 'www.jd.com'
    currency: 'CNY'
    encoding: 'utf8'
    regexp: /jd\.com/
    generateProductUrl: (productId) ->
      return httpPrefix + @site.replace('www', 'wap') + '/product/' + \
             productId + htmlSuffix
  }
]

generateProductUrl = (id, site) ->
  matched = sites.filter((s) -> s.site == site)
  return switch matched.length
    when 0 then siteNotSupportHandler(site)
    when 1 then matched.pop().generateProductUrl(id)
    else multiMatchHandler('site')

getSiteCurrency = (site) ->
  matched = sites.filter((s) -> s.site == site)
  return switch matched.length
    when 0 then siteNotSupportHandler(site)
    when 1 then matched.pop().currency
    else multiMatchHandler('site')

getSiteEncoding = (site) ->
  matched = sites.filter((s) -> s.site == site)
  return switch matched.length
    when 0 then siteNotSupportHandler(site)
    when 1 then matched.pop().encoding
    else multiMatchHandler('site')

urlToSite = (url) ->
  matched = sites.filter((s) -> s.regexp.test(url))
  return switch matched.length
    when 0 then urlNotSupportHandler(url)
    when 1 then matched.pop().site
    else multiMatchHandler('regexp')

multiMatchHandler = (field) ->
  logger.error('there is multi matched sites on field %s', field)
  throw new Error('programming error, multi sites matched')

siteNotSupportHandler = (site) ->
  logger.error('site %s not support yet', site)
  throw new Error('value not support error, site')

urlNotSupportHandler = (url) ->
  logger.error('url %s not support', url)
  throw new Error('value not support error, url')

exports.generateProductUrl = generateProductUrl
exports.getSiteEncoding = getSiteEncoding
exports.getSiteCurrency = getSiteCurrency
exports.urlToSite = urlToSite
module.exports = exports
