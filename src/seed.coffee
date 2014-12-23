httpPrefix = "http://"
htmlSuffix = ".html"

siteTable =
  amazonCN: {
    url: "www.amazon.cn"
    generateProductUrl: (productId) ->
      return httpPrefix + @url + "/dp/" + productId
  }
  amazonUS: {
    url: "www.amazon.com"
    generateProductUrl: (productId) ->
      return httpPrefix + @url + "/dp/" + productId
  }
  amazonJP: {
    url: "www.amazon.co.jp"
    generateProductUrl: (productId) ->
      return httpPrefix + @url + "/dp/" + productId
  }
  jingdong: {
    url: "www.jd.com"
    generateProductUrl: (productId) ->
      return httpPrefix + @url.replace("www", "item") + "/" + \
             productId + htmlSuffix
  }

getSiteByUrl = (url) ->
  return (self for _, self of siteTable when self.url == url).pop()

loadPriceVerdict = (price, seed) ->
  if price.compare == "under"
    seed.verdictPrice = (x) ->
      return x < price.target
  else if price.compare == "above"
    seed.verdictPrice = (x) ->
      return price.target < x
  else if price.compare == "equal"
    seed.verdictPrice = (x) ->
      return x == price.target
  else
    logger.error("unknown price verdict word %s", price.compare)
    process.exit()
  return

loadDiscountVerdict = (discount, seed) ->
  if discount.compare == "under"
    seed.verdictDiscount = (x) ->
      return x < discount.target
  else if discount.compare == "above"
    seed.verdictDiscount = (x) ->
      return discount.target < x
  else if discount.compare == "equal"
    seed.verdictDiscount = (x) ->
      return x == discount.target
  else
    logger.error("unknown discount verdict %s", discount.compare)
    process.exit()
  return

loadReviewVerdict = (review, seed) ->
  reviewStar = ["zero", "half", "one", "one-half", "two", "two-half", "three", "three-half", "four", "four-half", "five"]
  score = reviewStar.indexOf(review.target)
  if review.compare == "above" and score != -1
    seed.verdictReview = (x) ->
      return score < x
  else if review.compare == "under"
    seed.verdictReview = (x) ->
      return x < score
  else if review.compare == "equal"
    seed.verdictReview = (x) ->
      return x == score
  else
    logger.error("unknown review verdict '%s %s'", review.comapre review.target)
    process.exit()
  return

loadBenefitVerdict = (benefit, seed) ->
  regex = new Regex(benefit.regex, benefit.option)
  seed.verdictBenefits = (benefits) ->
    return benefits.some((elt, idx, arr) ->
      return regex.test(elt))
  return

loadVerdict = (item, seed) ->
  if item.price
    loadPriceVerdict(item.price, seed)
  if item.discount
    loadDiscountVerdict(item.discount, seed)
  if item.review
    loadReviewVerdict(item.review, seed)
  if item.benefit
    loadBenefitVerdict(item.benefit, seed)

  return (result) ->
    ret = false
    if not ret and @verdictPrice
      ret = @verdictPrice(result.price)
    if not ret and @verdictDiscount
      ret = @verdictDiscount(result.discount)
    if not ret and @verdictReview
      ret = @verdictReview(result.review)
    if not ret and @verdictBenefits
      ret = @verdictBenefits(result.benefits)
    return ret

module.exports = (item) ->
  seed = {id: item.id, site: item.site}

  targetSite = getSiteByUrl(item.site)
  seed.url = targetSite.generateProductUrl(item.id)

  seed.verdict = loadVerdict(item, seed)
  return seed

# common deparment with valuable discount
availableDepartments =
  digitalMusic: "Digital Music"
  book: "Book"
  movie: "Movie"
  music: "Music"
  game: "Game"
  home: "Home"
  sport: "Sport"
  outdoor: "Outdoor"
  credit: "Credit"
