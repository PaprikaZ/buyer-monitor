path = require("path")
fs = require("fs")
global.rootRequire = (name) ->
  return require(path.join(__dirname, name))

logger = require('winston')
logger.add(logger.transports.File, filename: '/tmp/ebuy_monitor.log')
global.logger = logger

verifyUserTokens = (callback) ->
  request = require("request")
  userServiceUrl = rootRequire("src/config.js").userServiceUrl
  accessTokens = rootRequire("src/config.js").accounts.map((account) ->
    return account.accessToken
  )

  verifyToken = (token) ->
    options =
      url: userServiceUrl
      auth:
        user: token
    shortToken = token.slice(0, 7)
    makeVerifyOK = ->
      counter = accessTokens.length
      return ->
        counter -= 1
        logger.info("token %s verify ok", shortToken)
        if counter == 0
          logger.info("all token verify done.")
          callback()
        return
    printSuccess = makeVerifyOK()

    request.get(options, (err, res, body) ->
      if not err and res.statusCode == 200
        return printSuccess()
      else
        logger.warn("token %s verify failed", shortToken)
        logger.warn("error: %s", err)
        logger.warn("status code: %s", res.statusCode)
        logger.warn("failure message: %s", body)
        logger.error("account access token verify caught failed, exit.")
        process.exit()
        return
    )
    return

  logger.info("access token verifying ...")
  accessTokens.map(verifyToken)
  return

launchMonitor = ->
  seed = rootRequire("src/seed.js")
  monitorSeeds = JSON.parse(
    fs.readFileSync(path.join(__dirname, "product.json"))).map((item) ->
      return seed(item)
  )
  
  async = require("async")
  visitor = rootRequire("src/visitor.js")
  visit = (seed) ->
    v = visitor.select(seed)
    v.visit()
    return
  asyncParallelRequests = ->
    async.map(monitorSeeds, visit, (err, results) ->
      logger.error(err)
      return
    )
    return
  
  monitorInterval = rootRequire("src/config.js").monitorInterval

  asyncParallelRequests()
  setInterval(asyncParallelRequests, monitorInterval)
  #messager startup here

launch = ->
  verifyUserTokens(launchMonitor)
  return

argvParser = rootRequire("src/argv_parser.js")
argvParser.parse(process.argv.slice(2), launch)
