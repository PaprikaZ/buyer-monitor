util = require('util')
fs = require('fs')
path = require('path')
async = require('async')
request = require('request')
config = require('./config.js')
messenger = require('./messenger.js')
createVisitor = require('./visitor.js').createVisitor
s = require('./seed.js')
Seed = s.Seed
MANDATORY_BASE_FIELDS = s.MANDATORY_BASE_FIELDS
db = require('./db.js')
verdictsFileName = path.join(__dirname, '../', config.verdictsFileName)

shortenToken = (token) ->
  return token.slice(0, 7)

class Monitor
  constructor: ->
    @client = db.getClient()
    
    if 0 < config.accounts.length
      @accessTokens = config.accounts.map((account) ->
        return account.accessToken)
    else
      throw new Error('access tokens empty')

    verdicts = JSON.parse(fs.readFileSync(verdictsFileName))
    if 0 < verdicts.length
      @seeds = verdicts.map((item) -> new Seed(item))
    else
      throw new Error('products empty')
    logger.debug('load seeds ok.')

  verifyUserTokens: ->
    self = @
    problemTokens = []
    logger.info('user access tokens verifying ...')
          
    makeVerifyDone = ->
      counter = self.accessTokens.length
      return ->
        counter -= 1
        if counter <= 0
          logger.info('all access tokens verify done.')
          self.accessTokens = self.accessTokens.filter((token) ->
            return problemTokens.indexOf(token) == -1
          )
          if self.accessTokens.length != 0
            self.startMonitoring()
          else
            throw new Error('all access token is invalid')
        return
    verifyDone = makeVerifyDone()

    @accessTokens.map((token) ->
      shortToken = shortenToken(token)
      options =
        url: config.userServiceUrl
        auth:
          user: token

      request.get(options, (err, res, body) ->
        if not err and res.statusCode == 200
          logger.debug('token %s verify ok', shortToken)
        else if err
          logger.error('token %s verify caught request error.', shortToken)
          logger.error('%s %s', shortToken, err.message)
          problemTokens.push(token)
          logger.info('%s removed from subscribers', shortToken)
        else
          logger.warn('token %s is invalid', shortToken)
          logger.warn('%s status code: %s', shortToken, res.statusCode)
          logger.warn('%s url: %s', shortToken, res.url)
          logger.warn('%s message: %s', shortToken, body)
          problemTokens.push(token)
          logger.info('%s removed from subscribers', shortToken)

        verifyDone()
        return
      )
      return
    )
    return

  delaySeed: (id, site) ->
    self = @
    previousSeeds = @seeds
    @seeds = previousSeeds.filter((s) -> s.id != id or s.site != site)
    previousSeeds
      .filter((s) -> return s.id == id and s.site == site)
      .forEach((s) ->
        debugMsg = 'product '
        MANDATORY_BASE_FIELDS.map((field) ->
          debugMsg += util.format('%s %s', field, s[field])
          return
        )
        debugMsg += ' delayed'
        logger.info(debugMsg)

        setTimeout((->
          self.seeds.push(s)
          return
        ), config.resendDelay)
        return
    )
    return

  sendRequests: ->
    if 0 < @seeds.length
      @seeds.map((seed) ->
        createVisitor(seed).visit()
        return
      )
    return

  startMonitoring: ->
    self = @

    monitor = ->
      iter = ->
        self.client.rpop(config.redisDelayQueueKey, (err, res) ->
          if not err
            if res
              item = JSON.parse(res)
              self.delaySeed(item.id, item.site)
              iter()
            else
              logger.debug('processing delay queue done')
              self.sendRequests()
          else
            logger.error('rpop delay queue caught error')
            logger.error('message: %s', err.message)
            throw err
          return
        )
        return
      iter()
      return

    monitor()
    setInterval(monitor, config.monitorInterval)
    
    push = ->
      iter = ->
        results = []
        self.client.rpop(config.redisPushQueueKey, (err, res) ->
          if not err
            if res
              results.push(JSON.parse(res))
              iter()
            else
              logger.debug('processing push queue done')
              results.map((result) ->
                self.accessTokens.map((token) -> messenger.push(result, token)))
          else
            logger.error('rpop push queue caught error')
            logger.error('message: %s', err.message)
            throw err
          return
        )
        return
      iter()
      return
    setInterval(push, config.pushInterval)
    return

  start: ->
    @verifyUserTokens()
    return

module.exports.createMonitor = ->
  return new Monitor()
