fs = require("fs")
path = require("path")
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
      else if err
        logger.error("token %s verify caught request error.", shortToken)
        logger.error("error: %s", err)
        logger.error("account access token verify caught failed, exit.")
        process.exit()
      else
        logger.warn("token %s verify response error", shortToken)
        logger.warn("status code: %s", res.statusCode)
        logger.warn("error message: %s", body)
      return
    )
    return

  logger.info("access token verifying ...")
  accessTokens.map(verifyToken)
  return

launchMonitor = ->
  seed = rootRequire("src/seed.js")
  seeds = JSON.parse(
    fs.readFileSync(path.join(__dirname, "product.json"))).map((item) ->
      return seed(item)
  )
  

  delaySeed = (id, site) ->
    resendDelay = rootRequire("src/config.js").resendDelay
    seeds = seeds.filter((elt) ->
      return elt.id != id or elt.site != site
    )
    seeds.filter((elt) ->
      return elt.id == id and elt.site == site
    ).forEach((elt) ->
      pushSeedBack= ->
        seeds.push(elt)
        return
      logger.info("product id %s site %s delayed.", elt.id, elt.site)
      setTimeout(pushSeedBack, resendDelay)
      return
    )
    return
  

  async = require("async")
  visitor = rootRequire("src/visitor.js")
  monitorInterval = rootRequire("src/config.js").monitorInterval
  visit = (seed) ->
    v = visitor.select(seed)
    v.visit()
    return
  asyncParallelRequests = ->
    async.map(seeds, visit, (err, results) ->
      logger.error(err)
      return
    )
    return

  config = rootRequire("src/config.js")
  pushQueueKey = config.redisPushQueueKey
  db = rootRequire("src/db_client.js")
  client = db.newClient()
  iterate = ->
    iter = ->
      item = JSON.parse(client.rpop(pushQueueKey))
      if item.id and item.site
        delaySeed(item.id, item.site)
        iter()
      return

    iter()
    asyncParallelRequests()
    return

  asyncParallelRequests()
  setInterval(iterate, monitorInterval)

launch = ->
  verifyUserTokens(launchMonitor)
  return

argvParser = rootRequire("src/argv_parser.js")
argvParser.parse(process.argv.slice(2), launch)
