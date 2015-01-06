config = require('./config.js')
cheerio = require('cheerio')

_MANDATORY_PARSE_FIELDS = ['title', 'price', 'fullPrice', 'review', 'instore', 'benefits']
MANDATORY_FIELDS = ['title', 'price', 'fullPrice', 'discount', 'review', 'instore', 'benefits']
require('./seed.js').AVAILABLE_VERDICT_FIELDS.map((field) ->
  if MANDATORY_FIELDS.indexOf(field) == -1
    console.error('seed verdict field %s is missing in page parser result', field)
    throw new Error('missing seed verdict field')
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
  load: cheerio.load
  mandatoryParseFields: _MANDATORY_PARSE_FIELDS
  mandatoryFields: MANDATORY_FIELDS
  parse: (html) ->
    self = @
    $ = @load(html)
    result = {}
    @mandatoryParseFields.map((field) ->
      result[field] = self[field]($)
      return)
    result.discount = (1 - result.price / result.fullPrice) * 100

    allFieldOk = @mandatoryParseFields.every((field) ->
      return field != null)
    if allFieldOk
      return result
    else
      return logger.error('%s parse page failed', @constructor.name)

  title: (selector) ->
    return 'unknown'
  price: (selector) ->
    return -1
  fullPrice: (selector) ->
    return -1
  review: (selector) ->
    return review.unknownStar
  instore: (selector) ->
    return false
  benefits: (selector) ->
    return []

class AmazonCNParser extends Parser
  title: (selector) ->
    return selector('#productTitle').text()
  priceToInt: (text) ->
    return parseInt(text.slice(1).replace(',', ''))
  price: (selector) ->
    return @priceToInt(selector('#priceblock_ourprice').text())
  fullPrice: (selector) ->
    return @priceToInt(selector('#priceblock_ourprice').parent().parent()
      .parent().children().first().children().last().text())
  review: (selector) ->
    classes = selector('#acrPopover').children().children()
      .children('.a-icon-star').attr('class')
    if /a-star-5/.test(classes)
      return review.fiveStar
    else if /a-star-4-5/.test(classes)
      return review.fourHalfStar
    else if /a-star-4/.test(classes)
      return review.fourStar
    else if /a-star-3-5/.test(classes)
      return review.threeStar
    else if /a-star-3/.test(classes)
      return review.threeStar
    else if /a-star-2-5/.test(classes)
      return review.twoHalfStar
    else if /a-star-2/.test(classes)
      return review.twoStar
    else if /a-star-1-5/.test(classes)
      return review.oneHalfStar
    else if /a-star-1/.test(classes)
      return review.oneStar
    else if /a-star-0-5/.test(classes)
      return review.halfStar
    else if /a-star-0/.test(classes)
      return review.zeroStar
    else
      return review.unknownStar
  instore: (selector) ->
    classes = selector('#ddmAvailabilityMessage').children().attr('class')
    if /a-color-success/.test(classes)
      return true
    else
      return false

class AmazonUSParser extends Parser
class AmazonJPParser extends Parser
class JingdongParser extends Parser

module.exports.MANDATORY_FIELDS = MANDATORY_FIELDS
module.exports.createParser = (site) ->
  parser =
    switch site
      when 'www.amazon.cn' then new AmazonCNParser()
      when 'www.amazon.com' then new AmazonUSParser()
      when 'www.amazon.co.jp' then new AmazonJPParser()
      when 'www.jd.com' then new JingdongParser()
      else
        logger.error('no available page parser for site %s', site)
        throw new Error('no available parser')
  return parser
