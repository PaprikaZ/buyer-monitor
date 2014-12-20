path = require("path")
fs = require("fs")
global.rootRequire = (name) ->
  return require(path.join(__dirname, name))

logger = require('winston')
logger.add(logger.transports.File, filename: '/tmp/ebuy_monitor.log')
global.logger = logger

async = require("async")
seed = rootRequire("src/seed.js")
visitor = rootRequire("src/visitor.js")
monitorInterval = rootRequire("src/config.js").monitorInterval

monitorSeeds = JSON.parse(fs.readFileSync(path.join(__dirname, "monitor.json"))).map((item) ->
    return seed(item.id, item.site)
)
asyncParallelRequests = ->
  async.parallel(monitorSeeds.map((seed) ->
    return ->
      v = visitor.select(seed.siteUrl)
      v.visit(seed.url)
      return
    ), (err) ->
      console.log(err)
      return
  )
  return
setInterval(asyncParallelRequests, monitorInterval)
#messager startup here
