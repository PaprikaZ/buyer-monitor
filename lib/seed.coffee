config = require('./config.js')

httpPrefix = 'http://'
httpsPrefix = 'https://'
htmlSuffix = '.html'

MANDATORY_BASE_FIELDS = ['id', 'site']
MANDATORY_VERDICT_FIELDS = ['price', 'discount', 'instore', 'review', 'benefits']
AVAILABLE_COMPARES = ['above', 'under', 'equal', 'match']
_MANDATORY_VERDICT_METHODS = MANDATORY_VERDICT_FIELDS.map((field) ->
  return 'verdict' + field.slice(0, 1).toUpperCase() + field.substring(1)
)

siteTable =
  amazonCN: {
    site: 'www.amazon.cn'
    generateProductUrl: (productId) ->
      return httpPrefix + @site + '/dp/' + productId
  }
  amazonUS: {
    site: 'www.amazon.com'
    generateProductUrl: (productId) ->
      return httpPrefix + @site + '/dp/' + productId
  }
  amazonJP: {
    site: 'www.amazon.co.jp'
    generateProductUrl: (productId) ->
      return httpPrefix + @site + '/dp/' + productId
  }
  jingdong: {
    site: 'www.jd.com'
    generateProductUrl: (productId) ->
      return httpPrefix + @site.replace('www', 'item') + '/' + \
             productId + htmlSuffix
  }

generateProductUrl = (site, id) ->
  matchedItems = (self for _, self of siteTable when self.site == site)
  if 0 < matchedItems.length
    return matchedItems.pop().generateProductUrl(id)
  else
    siteNotSupportHandler(site)
  return

siteNotSupportHandler = (site) ->
  logger.error('site %s is not support yet')
  throw new Error('product site not support error')

illegalTypeHandler = (id, site, field) ->
  logger.error('id %s site %s %s verdict with a illegal value', id, site, field)
  throw new Error('product illegal verdict value error')

verdictMissingHandler = (id, site) ->
  logger.error('id %s site %s missing verdict field', id, site)
  throw new Error('product missing verdict field error')

noneVerdictLoadedHandler = (id, site) ->
  logger.error('id %s site %s none verdict loaded', id, site)
  throw new Error('none verdict loaded')

class Seed
  constructor: (product) ->
    self = @
    MANDATORY_BASE_FIELDS.map((field) -> self[field] = product[field])
    @url = generateProductUrl(product.site, product.id)

    (->
      verdictLoaded = false
      MANDATORY_VERDICT_FIELDS.map((field) ->
        if product[field]
          if product[field].target != 'null'
            self[field] = product[field]
            verdictLoaded = true
          else
            illegalTypeHandler(product.id, product.site, field)
        return
      )
      not verdictLoaded and verdictMissingHandler(product.id, product.site)
      return
    )()

    if product.price
      @verdictPrice = (x) ->
        return x.price < product.price.target

    if product.discount
      @verdictDiscount = (x) ->
        return product.discount.target < x.discount

    if product.review
      @verdictReview = (x) ->
        return product.review.target < x.review

    if product.instore
      @verdictInstore = (x) ->
        return x.instore == product.instore

    if product.benefits
      regex = new RegExp(product.benefits.regex, product.benefits.option)
      @verdictBenefits = (x) ->
        return x.benefits.some((elt) -> return regex.test(elt))

    if _MANDATORY_VERDICT_METHODS.filter((verdict) -> self[verdict]).length == 0
      noneVerdictLoadedHandler(product.id, product.site)

    return

  verdict: (result) ->
    self = @
    ret = _MANDATORY_VERDICT_METHODS
      .filter((verdict) ->
        return self[verdict]
      )
      .reduce(((partial, verdict) ->
        return partial and self[verdict](result)
      ), true)
    return ret

module.exports.Seed = Seed
module.exports.MANDATORY_BASE_FIELDS = MANDATORY_BASE_FIELDS
module.exports.MANDATORY_VERDICT_FIELDS = MANDATORY_VERDICT_FIELDS
module.exports.AVAILABLE_COMPARES = AVAILABLE_COMPARES
