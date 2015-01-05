util = require('util')
fs = require('fs')
path = require('path')
async = require('async')
request = require('request')
config = require('./config.js')
createVisitor = require('./visitor.js').createVisitor
s = require('./seed.js')
Seed = s.Seed
MANDATORY_BASE_FIELDS = s.MANDATORY_BASE_FIELDS
db = require('./db.js')
productFile = '../product.json'

shortenToken = (token) ->
  return token.slice(0, 7)

class Monitor
  constructor: ->
    self = @

    @client = db.getClient()
    
    if 0 < config.accounts.length
      @accessTokens = config.accounts.map((account) ->
        return account.accessToken)
    else
      throw new Error('access token empty')

    verdicts = JSON.parse(fs.readFileSync(path.join(__dirname, productFile)))
    if 0 < verdicts.length
      @seeds = verdicts.map((item) -> new Seed(item))
    else
      throw new Error('products empty')
    logger.debug('load seeds ok.')

  verifyUserTokens: (callback) ->
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
            callback()
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
        else if res.statusCode == 401
          logger.warn('token %s is invalid', shortToken)
          logger.warn('%s status code: %s', shortToken, res.statusCode)
          logger.warn('%s message: %s', shortToken, body)
          problemTokens.push(token)
          logger.info('%s removed from subscribers', shortToken)
        else
          logger.warn('token %s is invalid', shortToken)
          logger.warn('%s status code: %s', shortToken, res.statusCode)
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
    previousSeeds = self.seeds
    self.seeds = previousSeeds.filter((s) -> s.id != id or s.site != site)
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

  startMonitorInterval: ->
    self = @

    setInterval((->
      iter = ->
        self.client.rpop(config.redisPushQueueKey, (err, res) ->
          if not err
            if res
              item = JSON.parse(res)
              self.delaySeed(item.id, item.site)
              iter()
            else
              logger.debug('delay push queue done')
              self.sendRequests()
          else
            logger.error('rpop push queue caught error')
            logger.error('message: %s', err.message)
            throw err
          return
        )
        return
      iter()
      return
    ), config.monitorInterval)
    return

  start: ->
    @verifyUserTokens(@startMonitorInterval)
    return

module.exports.createMonitor = ->
  return new Monitor()
