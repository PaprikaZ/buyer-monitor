fs = require('fs')
path = require('path')
async = require('async')
request = require('request')
config = require('./config.js')
Visitor = require('./visitor.js')
Seed = require('./seed.js')
DBClient = require('./db_client.js')
productFile = '../product.json'

class Monitor
  constructor: ->
    self = @
    @accessTokens = config.accounts.map((account) ->
      return account.accessToken)

    @seeds = JSON.parse(
      fs.readFileSync(path.join(__dirname, productFile))).map((item) ->
        return new Seed(item))
    logger.info("load seeds ok.")

    @client = DBClient()
    @client.del(config.pushQueueKey, (err, res) ->
      if err
        logger.error("Clear push queue %s failed.", config.pushQueueKey)
        logger.error("%s", err)
        process.exit()
      return)
    logger.info("Launcher clear push queue ok.")


  verifyUserTokens: ->
    self = @
    logger.info("user access tokens verifying ...")
    @accessTokens.map((token) ->
      shortToken = token.slice(0, 7)
      options =
        url: config.userServiceUrl
        auth:
          user: token
      makeVerifyOK = ->
        counter = self.accessTokens.length
        return ->
          counter -= 1
          if counter == 0
            logger.info("all access tokens verify done.")
            self.startMonitorInterval()
          return
      printSuccess = makeVerifyOK()

      request.get(options, (err, res, body) ->
        if not err and res.statusCode == 200
          return printSuccess()
        else if err
          logger.error("token %s verify caught request error.", shortToken)
          logger.error("%s", err)
          logger.error("account access token verify caught failed, exit.")
          process.exit()
        else if res.statusCode == 401
          accessTokens = accessTokens.filter((elt) ->
            return elt != token)
          logger.warn("token %s is invalid, removed.", shortToken)
          logger.warn("status code: %s", res.statusCode)
          logger.warn("error message: %s", body)
        else
          logger.warn("token %s verify response error", shortToken)
          logger.warn("status code: %s", res.statusCode)
          logger.warn("error message: %s", body)
        return)
      return)
    return

  delaySeed: (id, site) ->
    self = @
    previousSeeds = self.seed
    self.seeds = previousSeeds.filter((elt) ->
      return elt.id != id or elt.site != site)
    previousSeeds.filter((elt) ->
      return elt.id == id and elt.site == site
    ).forEach((elt) ->
      pushSeedBack= ->
        self.seeds.push(elt)
        return
      logger.info("product id %s site %s delayed.", elt.id, elt.site)
      setTimeout(pushSeedBack, config.resendDelay)
      return
    )
    return

  sendRequests: ->
    visit = (seed) ->
      v = Visitor(seed)
      v.visit()
      return
    if @seeds.length != 0
      async.map(@seeds, visit, (err, results) ->
        logger.error(err)
        return)
    return

  startMonitorInterval: ->
    self = @
    iterate = ->
      iter = ->
        @client.rpop(config.pushQueueKey, (err, res) ->
          item = JSON.parse(res)
          logger.debug("pop delay id %s site %s", item.id, item.site)
          if item
            self.delaySeed(item.id, item.site)
            iter()
          else
            logger.debug("iteration done.")
            self.sendRequests()
          return)
      iter()
      return

    @sendRequests()
    setInterval(iterate, config.monitorInterval)
    return

  start: ->
    @verifyUserTokens()
    return

launch = ->
  monitor = new Monitor()
  monitor.start()
  return

module.exports.launch = ->
  require('./argv_parser.js').parse(process.argv.slice(2), launch)
  return
module.exports.config = require('./config.js')
module.exports.argvParser = require('./argv_parser.js')
module.exports.DBClient = require('./db_client.js')
module.exports.Messenger = require('./messenger.js')
module.exports.PageParser = require('./page_parser.js')
module.exports.Seed = require('./seed.js')
module.exports.Visitor = require('./visitor.js')
