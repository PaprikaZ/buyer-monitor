httpPrefix = 'http://'
httpsPrefix = 'https://'
htmlSuffix = '.html'

MANDATORY_BASE_FIELD = ['id', 'site']
MANDATORY_VERDICT_FIELD = ['price', 'discount', 'instore', 'review']

siteTable =
  amazonCN: {
    site: "www.amazon.cn"
    generateProductUrl: (productId) ->
      return httpPrefix + @site + "/dp/" + productId
  }
  amazonUS: {
    site: "www.amazon.com"
    generateProductUrl: (productId) ->
      return httpPrefix + @site + "/dp/" + productId
  }
  amazonJP: {
    site: "www.amazon.co.jp"
    generateProductUrl: (productId) ->
      return httpPrefix + @site + "/dp/" + productId
  }
  jingdong: {
    site: "www.jd.com"
    generateProductUrl: (productId) ->
      return httpPrefix + @site.replace("www", "item") + "/" + \
             productId + htmlSuffix
  }

getProductUrl = (site, id) ->
  return (self for _, self of siteTable when self.site == site).pop().generateProductUrl(id)

returnFalse = ->
  return false

class Seed
  constructor: (product) ->
    for attr, val of product
      @[attr] = val
    @url = getProductUrl(@site, @id)

    if product.price and product.price.compare == 'under'
      @verdictPrice = (x) ->
        return x < product.price.target
    else if not product.price
      @verdictPrice = returnFalse
    else
      logger.error("unknown price compare keyword %s", product.price.compare)
      process.exit()

    if product.discount and product.discount.comapre == 'above'
      @verdictDiscount = (x) ->
        return product.discount.target < x
    else if not product.discount
      @verdictDiscount = returnFalse
    else
      logger.error("unknown discount compare keyword %s", product.discount.compare)
      process.exit()

    reviewStar = ["zero", "half", "one", "one-half", "two", "two-half", "three", "three-half", "four", "four-half", "five"]
    if product.review and product.review.compare = 'above'
      score = reviewStar.indexOf(product.review)
      if score != -1
        @verdictReview = (x) ->
          return product.review.target < x
      else
        logger.error("unknown review target keyword %s", product.review.target)
    else if not product.review
      @verdictReview = returnFalse
    else
      logger.error("unknown review compare keyword %s", product.review.compare)
      process.exit

    if product.benefit
      regex = new Regex(product.benefit.regex, product.benefit.option)
      @verdictBenefits = (benefits) ->
        return benefits.some((elt, idx, arr) ->
          return regex.test(elt))
    else
      @verdictBenefits = returnFalse

  verdict: (result) ->
    ret = false
    ret = @verdictPrice(result.price) or @verdictDiscount(result.discount)
    ret = ret and @verdictReview(result.review)
    ret = ret and @verdictBenefits(result.benefits)
    return ret

module.exports.Seed = Seed
module.exports.MANDATORY_BASE_FIELD = MANDATORY_BASE_FIELD
module.exports.MANDATORY_VERDICT_FIELD = MANDATORY_VERDICT_FIELD

