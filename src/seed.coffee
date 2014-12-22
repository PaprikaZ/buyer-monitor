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
    console.log("unknown price verdict word %s", price.compare)
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
    console.log("unknown discount verdict %s", discount.compare)
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
  if item.benefit
    loadBenefitVerdict(item.benefit, seed)

  return (result) ->
    result = false
    if reulst or @verdictPrice
      result = result or @verdictPrice(result.price)
    if result or @verdictDiscount
      result = result or @verdictDiscount(result.discount)
    if result or @verdictBenefits
      result = result or @verdictBenefits(result.benefits)
    return result

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
