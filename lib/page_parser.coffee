config = require('./config.js')
cheerio = require('cheerio')

_MANDATORY_PARSE_FIELDS = ['title', 'price', 'fullPrice', 'review', 'instore', 'benefits']
_MANDATORY_EXPAND_FIELDS = ['discount']
MANDATORY_OUTPUT_FIELDS = _MANDATORY_PARSE_FIELDS.concat(_MANDATORY_EXPAND_FIELDS)
require('./seed.js').AVAILABLE_VERDICT_FIELDS.map((field) ->
  if MANDATORY_OUTPUT_FIELDS.indexOf(field) == -1
    console.error('seed verdict field %s is missing in page parser result', field)
    throw new Error('design error, page parser output missing verdict field')
  return
)

review =
  fiveStar: 10
  fourHalfStar: 9
  fourStar: 8
  threeHalfStar: 7
  threeStar: 6
  twoHalfStar: 5
  twoStar: 4
  oneHalfStar: 3
  oneStar: 2
  halfStar: 1
  zeroStar: 0
  unknownStar: -1

class Parser
  constructor: ->
  parse: (html) ->
    self = @
    $ = cheerio.load(html)

    result = {}
    _MANDATORY_PARSE_FIELDS.map((field) ->
      result[field] = self[field]($)
      return
    )
    result.discount = @generateDiscount(result.price, result.fullPrice)

    console.log(result)
    MANDATORY_OUTPUT_FIELDS.some((field) ->
      return result[field] == '' or
             result[field] != result[field] or
             result[field] == -1 or
             result[field] < 0
    ) and
      parseErrorHandler(@constructor.name)
    return result

  title: (selector) ->
    return 'unknown'
  price: (selector) ->
    return -1
  fullPrice: (selector) ->
    return -1
  review: (selector) ->
    return review.unknownStar
  instore: (selector) ->
    return -1
  benefits: (selector) ->
    return ['foo']
  generateDiscount: (price, fullPrice) ->
    if fullPrice == 0
      return 0
    else
      return Math.round((1 - price / fullPrice) * 100)

class AmazonParser extends Parser
  title: (selector) ->
    return selector('#productTitle').text()
  priceToInt: (text) -> parseInt(text.slice(1).replace(',', ''))
  price: (selector) ->
    return @priceToInt(selector('#priceblock_ourprice').text())
  fullPrice: (selector) ->
    p = @priceToInt(selector('#priceblock_ourprice').parent().parent()
          .parent().children().first().children().last().text())
    if p != p
      return 0
    else
      return p
  review: (selector) ->
    classes = selector('#acrPopover').children().children()
      .children('.a-icon-star').attr('class')
    return switch
      when /a-star-5/.test(classes) then review.fiveStar
      when /a-star-4-5/.test(classes) then review.fourHalfStar
      when /a-star-4/.test(classes) then review.fourStar
      when /a-star-3-5/.test(classes) then review.threeHalfStar
      when /a-star-3/.test(classes) then review.threeStar
      when /a-star-2-5/.test(classes) then review.twoHalfStar
      when /a-star-2/.test(classes) then review.twoStar
      when /a-star-1-5/.test(classes) then review.oneHalfStar
      when /a-star-1/.test(classes) then review.oneStar
      when /a-star-0-5/.test(classes) then review.halfStar
      when /a-star-0/.test(classes) then review.zeroStar
      else review.unknownStar
  benefits: -> ['bar']

class AmazonCNParser extends AmazonParser
  instore: (selector) ->
    classes = selector('#ddmAvailabilityMessage').children().attr('class')
    return /a-color-success/.test(classes)

class AmazonUSParser extends AmazonParser
  instore: (selector) ->
    classes = selector('#availability').children().attr('class')
    return /a-color-success/.test(classes)

class AmazonJPParser extends AmazonParser
class JingdongParser extends Parser
  title: (selector) ->
    return selector('title').text().split(' - ')[0]
  priceToInt: (text) -> parseInt(text.slice(1))
  price: (selector) ->
    return @priceToInt(selector('.p-price > font:nth-child(1)').text())
  fullPrice: (selector) -> 0
  review: (selector) -> review.zeroStar
  instore: (selector) ->
    instoreText = selector('.p-stock > span:nth-child(1)').text()
    if /有货/.test(instoreText)
      return true
    else
      return false
  benefits: -> ['placeholder']

parseErrorHandler = (parserName) ->
  logger.error('%s parse failed', parserName)
  throw new Error('parse error')

invalidSiteHandler = (site) ->
  logger.error('no available parser for site %s', site)
  throw new Error('invalid data error, no available parser for invalid site')

exports.MANDATORY_OUTPUT_FIELDS = MANDATORY_OUTPUT_FIELDS
exports.createParser = (site) ->
  parser =
    switch site
      when 'www.amazon.cn' then new AmazonCNParser()
      when 'www.amazon.com' then new AmazonUSParser()
      when 'www.amazon.co.jp' then new AmazonJPParser()
      when 'www.jd.com' then new JingdongParser()
      else invalidSiteHandler(site)
  return parser
module.exports = exports
