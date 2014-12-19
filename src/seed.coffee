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

module.exports = (id, siteUrl) ->
  targetSite = getSiteByUrl(siteUrl)
  return {
    id: id
    siteUrl: siteUrl
    url: targetSite.generateProductUrl(id)
  }

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
