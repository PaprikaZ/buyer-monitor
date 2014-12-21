path = require("path")
fs = require("fs")
global.rootRequire = (name) ->
  return require(path.join(__dirname, name))

logger = require('winston')
logger.add(logger.transports.File, filename: '/tmp/ebuy_monitor.log')
global.logger = logger

launchMonitor = ->
  seed = rootRequire("src/seed.js")
  monitorSeeds = JSON.parse(
    fs.readFileSync(path.join(__dirname, "product.json"))).map((item) ->
      return seed(item.id, item.site)
  )
  
  async = require("async")
  visitor = rootRequire("src/visitor.js")
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
  
  monitorInterval = rootRequire("src/config.js").monitorInterval
  setInterval(asyncParallelRequests, monitorInterval)
  #messager startup here

argvParser = rootRequire("src/argv_parser.js")
argvParser.parse(process.argv.slice(2), launchMonitor)
