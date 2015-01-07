util = require('util')
fs = require('fs')
path = require('path')
config = require('./config.js')
messenger = require('./messenger.js')
db = require('./db.js')
token = require('./token.js')
createVisitor = require('./visitor.js').createVisitor
s = require('./seed.js')
Seed = s.Seed
MANDATORY_BASE_FIELDS = s.MANDATORY_BASE_FIELDS
verdictsFileName = path.join(__dirname, '../', config.verdictsFileName)

databaseErrorHandler = (err) ->
  logger.error('database module caught error')
  logger.error('db error: %s', err.message)
  throw err

class Monitor
  constructor: ->
    @client = db.getClient()
    
    if 0 < config.accounts.length
      @accessTokens = config.accounts.map((account) -> account.accessToken)
    else
      throw new Error('config error, access tokens empty')

    verdicts = JSON.parse(fs.readFileSync(verdictsFileName))
    if 0 < verdicts.length
      @seeds = verdicts.map((item) -> new Seed(item))
    else
      throw new Error('config error, verdicts empty')
    logger.debug('load seeds ok.')

  delaySeed: (id, site) ->
    self = @

    previousSeeds = @seeds
    @seeds = previousSeeds.filter((s) -> s.id != id or s.site != site)
    previousSeeds.filter((s) -> return s.id == id and s.site == site).forEach((s) ->
      debugMsg = 'product '
      MANDATORY_BASE_FIELDS.map((field) ->
        debugMsg += util.format('%s %s', field, s[field])
        return
      )
      debugMsg += ' delayed'
      logger.info(debugMsg)

      setTimeout((-> self.seeds.push(s)), config.resendDelay)
      return
    )
    return

  visitSites: ->
    0 < @seeds.length and @seeds.map((seed) -> createVisitor(seed).visit())
    return

  processDelayQueue: ->
    self = @

    iter = ->
      self.client.rpop(config.redisDelayQueueKey, (err, res) ->
        if not err
          if res
            item = JSON.parse(res)
            self.delaySeed(item.id, item.site)
            iter()
          else
            logger.debug('processing delay queue done')
            self.visitSites()
        else
          databaseErrorHandler(err)
        return
      )
      return
    iter()
    return

  pushMessages: (results) ->
    results.map((result) ->
      self.accessTokens.map((token) -> messenger.push(result, token)))
    return

  processPushQueue: ->
    self = @

    iter = ->
      results = []
      self.client.rpop(config.redisPushQueueKey, (err, res) ->
        if not err
          if res
            results.push(JSON.parse(res))
            iter()
          else
            logger.debug('fetch push queue done')
            self.pushMessages(results)
        else
          databaseErrorHandler(err)
        return
      )
      return
    iter()
    return

  startMonitoring: ->
    self = @
    setInterval(self.processDelayQueue, config.monitorInterval)
    setInterval(self.processPushQueue, config.pushInterval)
    return

  start: ->
    self = @

    token.verify()
    poll = setInterval((->
      if token.isVerificationDone()
        clearInterval(poll)
        self.accessTokens = token.getValidTokens()
        self.startMonitoring()
      return
    ), config.pollInterval)
    return

exports.createMonitor = ->
  return new Monitor()
module.exports = exports
