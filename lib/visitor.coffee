request = require('request')
config = require('./config.js')
Parser = require('./page_parser.js')
Messenger = require('./messenger.js')
DBClient = require('./db_client.js')
client = DBClient()

class Visitor
  constructor: (seed) ->
    @seed = seed

  visit: ->
    self = this
    request(self.seed.url, (err, res, body) ->
      if not err and res.statusCode == 200
        self.processPage(body)
      else if not err and res.statusCode != 200
        self.errorResponseHandler(err, res, body)
      else
        self.failedRequestHandler(err, res, body)
      return)
    return

  failedRequestHandler: (err, res, body) ->
    logger.error("%s visitor request failed.", @constructor.name)
    logger.error("err: %s", err)
    return

  errorResponseHandler: (err, res, body) ->
    logger.error("%s visitor response error.", @constructor.name)
    logger.error("url: %s", @seed.url)
    logger.error("response status code: %s", res.statusCode)
    logger.error("response body: %s", body)
    return

  processPage: (html) ->
    date = new Date()
    result = @parsePage(html)
    @pushQueue(result)

    result.date = date.toUTCString()
    @pushRecord(result)
    return

  parsePage: (html) ->
    parser = Parser(@seed.site)
    result = id: @seed.id, site: @seed.site, url: @seed.url
    for attr, val of parser.parse(html)
      result[attr] = val
    console.log(result)
    return result

  pushQueue: (result) ->
    if @seed.verdict(result)
      messenger = new Messenger()
      messenger.push(result)
      logger.debug("push delay id %s site %s", result.id, result.site)
      client.lpush(config.pushQueueKey, JSON.stringify({id: result.id, site:result.site}))
    return

  pushRecord: (record) ->
    client.lpush(config.historyKey, JSON.stringify(record))
    return

class AmazonCNVisitor extends Visitor

class AmazonUSVisitor extends Visitor

class AmazonJPVisitor extends Visitor

class JingDongVisitor extends Visitor

module.exports = (seed) ->
  newVisitor =
    switch seed.site
      when 'www.amazon.com' then new AmazonUSVisitor(seed)
      when 'www.amazon.cn' then new AmazonCNVisitor(seed)
      when 'www.amazon.co.jp' then new AmazonJPVisitor(seed)
      when 'www.jd.com' then new JingDongVisitor(seed)
      else logger.warn("there is no available visitor for site %s", seed.site)
  return newVisitor
