request = require('request')
util = require('util')
config = require('./config.js')
s = require('./seed.js')
MANDATORY_EXPAND_FIELDS = s.MANDATORY_EXPAND_FIEL
MANDATORY_BASE_FIELDS = s.MANDATORY_BASE_FIELDS
createParser = require('./page_parser.js').createParser
Messenger = require('./messenger.js')
db = require('./db_client.js')

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
          self.errorResponseHandler(res, body)
      else
        self.failedRequestHandler(err)
      return
    )
    return

  failedRequestHandler: (err) ->
    logger.error('%s request failed.', @constructor.name)
    logger.error('msg: %s', err.message)
    throw err
    return

  errorResponseHandler: (res, body) ->
    logger.error('%s response error.', @constructor.name)
    logger.error('url: %s', res.url)
    logger.error('status code: %s', res.statusCode)
    logger.error('body: %s', body)
    return

  processPage: (html) ->
    date = new Date()
    result = @parsePage(html)

    if @seed.verdict(result)
      delayDebugMsg = 'push delay '
      MANDATORY_BASE_FIELDS.map((field) ->
        delayDebugMsg += util.format('%s %s', field, result[field])
        return
      )
      logger.debug(delayDebugMsg)

      messenger = new Messenger()
      messenger.push(result)

      pushMsg = {}
      MANDATORY_BASE_FIELDS.map((field) ->
        pushMsg[field] = result[field]
        return
      )
      @client.lpush(config.pushQueueKey, JSON.stringify(pushMsg))

    result.date = date.toUTCString()
    @client.lpush(config.historyKey, JSON.stringify(result))
    return

  parsePage: (html) ->
    self = @
    result = {}
    MANDATORY_EXPAND_FIELDS.map((field) ->
      result[field] = self.seed[field]
      return
    )

    for attr, val of createParser(@seed.site).parse(html)
      result[attr] = val
    logger.info(result)
    return result

class AmazonCNVisitor extends Visitor

class AmazonUSVisitor extends Visitor

class AmazonJPVisitor extends Visitor

class JingDongVisitor extends Visitor

module.exports.createVisitor = (seed) ->
  visitor =
    switch seed.site
      when 'www.amazon.com' then new AmazonUSVisitor(seed)
      when 'www.amazon.cn' then new AmazonCNVisitor(seed)
      when 'www.amazon.co.jp' then new AmazonJPVisitor(seed)
      when 'www.jd.com' then new JingDongVisitor(seed)
      else
        logger.error('there is no available visitor for site %s', seed.site)
        throw new Error('no available visitor')
  return visitor
