#lang coffeescript

request = require("request")
cheerio = require("cheerio")

availableSites =
  amazonCN: "www.amazon.cn"
  amazonUS: "www.amazon.com"

monitorItems = [
  {
    id: "B00K68MONW"
    site: availableSites.amazonCN
    category: "laptop"
    url: "http://www.amazon.cn/dp/B00K68MONW"
  }
  {
    id: "B00MFC4UGG"
    site: availableSites.amazonCN
    category: "laptop"
    url: "http://www.amazon.cn/dp/B00MFC4UGG"
  }
  {
    id: "B00MFEI7RW"
    site: availableSites.amazonCN
    category: "laptop"
    url: "http://www.amazon.cn/dp/B00MFEI7RW"
  }
]

monitorItems.map((item) ->
  request(item.url, (error, response, body) ->
    if ((not error) and response.statusCode == 200)
      $ = cheerio.load(body)
      $('#priceblock_ourprice').each(->
        console.log('%s', $(this).text())
        return
      )
    return
  )
  return
)
