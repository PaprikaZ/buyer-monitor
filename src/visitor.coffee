request = require("request")
cheerio = require("cheerio")
config = rootRequire("src/config.js")
redisPort = config.redisPort
redisHost = config.redisHost
redisRecordDBIndex = config.redisRecordDBIndex
redisPushMsgQueueDBIndex =config.redisPushMsgQueueDBIndex

redis = require("redis")
recordClient = redis.createClient(redisPort, redisHost)
recordClient.select(redisRecordDBIndex, (err, res) ->
  if not err
    logger.info("redis select %s %s", redisRecordDBIndex, res)
  else
    logger.error("redis select %s failed, %s", redisRecordDBIndex, err)
  return
)
recordClient.on("error", (err) ->
  logger.error("visitor record client caught error, %s", err)
  return
)
logger.info("redis record client connect success")

pushMsgClient = redis.createClient(redisPort, redisHost)
pushMsgClient.select(redisPushMsgQueueDBIndex, (err, res) ->
  if not err
    logger.info("redis select %s %s", redisPushMsgQueueDBIndex, res)
  else
    logger.error("redis select %s failed, %s", redisPushMsgQueueDBIndex, err)
  return
)
pushMsgClient.on("error", (err) ->
  logger.error("visitor push msg client caught error, %s", err)
  return
)
logger.info("redis push msg client connect success")

class Visitor
  constructor: (siteUrl) ->
    @siteUrl = siteUrl
  visit: (pageUrl) ->
  failRequestHandler: ->
  errorResponseHandler: ->
  parseProductPage: ->

class AmazonCNVisitor extends Visitor
  visit: (pageUrl) ->
    self = this
    request(pageUrl, (err, res, body) ->
      if err
        self.failRequestHandler(err, res)
      else if res.statusCode != 200
        self.errorResponseHandler(err, res)
      else
        self.parseProductPage(body)
      return
    )
    return
  
  failRequestHandler: (err, res) ->
  errorResponseHandler: (err, res) ->
  parseProductPage: (body) ->
    $ = cheerio.load(body)
    $('#priceblock_ourprice').each(->
      console.log('parse product price %s', $(this).text())
      return
    )
    return

class AmazonUSVisitor extends Visitor

class AmazonJPVisitor extends Visitor

class JingDongVisitor extends Visitor

module.exports.select = (siteUrl) ->
  newVisitor =
    switch siteUrl
      when "www.amazon.com" then new AmazonUSVisitor(siteUrl)
      when "www.amazon.cn" then new AmazonCNVisitor(siteUrl)
      when "www.amazon.co.jp" then new AmazonJPVisitor(siteUrl)
      when "www.jd.com" then new JingDongVisitor(siteUrl)
      else logger.warn("there is no available visitor for site %s", siteUrl)
  return newVisitor
