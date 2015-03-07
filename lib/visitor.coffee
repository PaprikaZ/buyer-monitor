request = require('request')
util = require('util')
iconv = require('iconv-lite')
config = require('./config.js')
s = require('./seed.js')
MANDATORY_EXPAND_FIELDS = s.MANDATORY_EXPAND_FIELDS
MANDATORY_BASE_FIELDS = s.MANDATORY_BASE_FIELDS
createParser = require('./page_parser.js').createParser
db = require('./db.js')
Record = require('./model.js').Record

class Visitor
  constructor: (seed) ->
    @seed = seed
    @redisClient = db.getRedisClient()

  visit: ->
    self = this
    request.get({
      url: self.seed.url
      encoding: null
    }, (err, res, body) ->
      if not err
        if res.statusCode == 200
          self.processPage(iconv.decode(new Buffer(body), self.seed.encoding))
        else
          responseErrorHandler(self.constructor.name, res, body)
      else
        requestErrorHandler(self.constructor.name, self.seed.url, err)
      return
    )
    return

  processPage: (html) ->
    result = @parsePage(html)
    @seed.verdict(result) and @pushToQueue(result)
    @writePersistRecord(result)
    return

  pushToQueue: (result) ->
    delayDebugMsg = 'push and delay '
    MANDATORY_BASE_FIELDS.map((field) ->
      delayDebugMsg += util.format('%s %s', field, result[field])
      return
    )
    logger.debug(delayDebugMsg)

    delayMsg = {}
    MANDATORY_BASE_FIELDS.map((field) ->
      delayMsg[field] = result[field]
      return
    )
    @redisClient.lpush(config.redisDelayQueueKey, JSON.stringify(delayMsg),
      (err) -> err and db.redisErrorRethrow(err))
    @redisClient.lpush(config.redisPushQueueKey, JSON.stringify(result),
      (err) -> err and db.redisErrorRethrow(err))
    return

  writePersistRecord: (result) ->
    console.log(result)
    new Record({
      id: result.id
      site: result.site
      url: result.url
      created: new Date().toUTCString()
      name: result.title
      price: result.price
      fullPrice: result.fullPrice
      currency: result.currency
      instore: result.instore
      review: result.review
      benefits: result.benefits
    }).save()
    return

  parsePage: (html) ->
    self = @
    result = {}

    mountField = (field) ->
      result[field] = self.seed[field]
      return
    MANDATORY_BASE_FIELDS.map(mountField)
    MANDATORY_EXPAND_FIELDS.map(mountField)

    for field, val of createParser(@seed.site).parse(html)
      result[field] = val
    logger.debug(result)
    return result

class AmazonCNVisitor extends Visitor
class AmazonUSVisitor extends Visitor
class AmazonJPVisitor extends Visitor
class JingDongVisitor extends Visitor

requestErrorHandler = (visitorName, url, err) ->
  logger.error('%s get request failed', visitorName)
  logger.error('%s url: %s', visitorName, url)
  logger.error('%s err: %s', visitorName, err.message)
  throw err

responseErrorHandler = (visitorName, res, body) ->
  logger.error('%s response error', visitorName)
  logger.error('%s url: %s', visitorName, res.url)
  logger.error('%s status code: %s', visitorName, res.statusCode)
  logger.error('%s body: %s', visitorName, body)
  return

invalidSiteHandler = (site) ->
  logger.error('no available visitor for site %s', site)
  throw new Error('invalid data error, no available visitor for invalid site')

exports.createVisitor = (seed) ->
  visitor =
    switch seed.site
      when 'www.amazon.com' then new AmazonUSVisitor(seed)
      when 'www.amazon.cn' then new AmazonCNVisitor(seed)
      when 'www.amazon.co.jp' then new AmazonJPVisitor(seed)
      when 'www.jd.com' then new JingDongVisitor(seed)
      else invalidSiteHandler(seed.site)
  return visitor
module.exports = exports
