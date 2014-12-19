request = require("request")
cheerio = require("cheerio")
seed = require("./seed.js")

monitorItems = [
  seed("B00K68MONW", "www.amazon.cn"),
  seed("B00MFC4UGG", "www.amazon.cn"),
  seed("B00MFEI7RW", "www.amazon.cn")
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
