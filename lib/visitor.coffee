request = require('request')
util = require('util')
config = require('./config.js')
s = require('./seed.js')
MANDATORY_EXPAND_FIELDS = s.MANDATORY_EXPAND_FIELDS
MANDATORY_BASE_FIELDS = s.MANDATORY_BASE_FIELDS
createParser = require('./page_parser.js').createParser
db = require('./db.js')

class Visitor
  constructor: (seed) ->
    @seed = seed
    @client = db.getClient()

  visit: ->
    self = this
    request.get(self.seed.url, (err, res, body) ->
      if not err
        if res.statusCode == 200
          self.processPage(body)
        else
          responseErrorHandler(self.constructor, res, body)
      else
        requestErrorHandler(self.constructor, self.seed.url, err)
      return
    )
    return

  processPage: (html) ->
    date = new Date()
    result = @parsePage(html)

    if @seed.verdict(result)
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
      @client.lpush(config.redisDelayQueueKey, JSON.stringify(delayMsg))
      @client.lpush(config.redisPushQueueKey, JSON.stringify(result))

    result.date = date.toUTCString()
    @client.lpush(config.redisHistoryKey, JSON.stringify(result))
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

requestErrorHandler = (visitor, url, err) ->
  logger.error('%s get request failed', visitor)
  logger.error('%s url: %s', visitor, url)
  logger.error('%s err: %s', visitor, err.message)
  throw err

responseErrorHandler = (visitor, res, body) ->
  logger.error('%s response error', visitor)
  logger.error('%s url: %s', visitor, res.url)
  logger.error('%s status code: %s', visitor, res.statusCode)
  logger.error('%s body: %s', visitor, body)
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
