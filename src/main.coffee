logger = require('winston')
logger.add(logger.transports.File, filename: '/tmp/ebuy_monitor.log')

seed = require("./seed.js")
visitor = require("./visitor.js")

monitorItems = [
  seed("B00K68MONW", "www.amazon.cn"),
  seed("B00MFC4UGG", "www.amazon.cn"),
  seed("B00MFEI7RW", "www.amazon.cn")
]

monitorItems.map((item) ->
  v = visitor.select(item.siteUrl)
  v.visit(item.url)
  return
)
