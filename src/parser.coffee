cheerio = require("cheerio")

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
  parse: (html) ->
    $ = @load(html)
    result = {}
    result.price = @price($)
    result.title = @title($)
    result.fullPrice = @fullPrice($)
    result.review = @review($)
    result.instore = @instore($)
    return result
  title: (selector) ->
  price: (selector) ->
  fullPrice: (selector) ->
  review: (selector) ->
  instore: (selector) ->

class AmazonCNParser extends Parser
  title: (selector) ->
    return selector('#productTitle').text()
  price: (selector) ->
    return selector('#priceblock_ourprice').text()
  fullPrice: (selector) ->
    return selector('#priceblock_ourprice').parent().parent().parent()
      .children().first().children().last().text()
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

module.exports.select = (site) ->
  newParser =
    switch site
      when "www.amazon.cn" then new AmazonCNParser()
      when "www.amazon.com" then new AmazonUSParser()
      when "www.amazon.co.jp" then new AmazonJPParser()
      when "www.jd.com" then new JingdongParser()
      else logger.warn(
        "there is no available parser for site %s",
        site
      )
  return newParser
