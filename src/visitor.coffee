request = require("request")
config = rootRequire("src/config.js")
selectParser = rootRequire("src/parser.js").select

redisPort = config.redisPort
redisHost = config.redisHost
redisRecordDBIndex = config.redisRecordDBIndex
historyKey = config.redisHistoryKey
pushQueueKey = config.redisPushQueueKey

redis = require("redis")
client = redis.createClient(redisPort, redisHost)
client.select(redisRecordDBIndex, (err, res) ->
  if not err
    logger.info("redis select %s %s", redisRecordDBIndex, res)
  else
    logger.error("redis select %s failed, %s", redisRecordDBIndex, err)
  return
)
client.on("error", (err) ->
  logger.error("visitor record client caught error, %s", err)
  return
)
logger.info("redis record client connect success")

class Visitor
  constructor: (seed) ->
    @seed = seed
  visit: ->
  failRequestHandler: ->
  errorResponseHandler: ->
  processPage: (html) ->
    date = new Date()
    result = @parsePage(html)
    @pushQueue(result)

    result.date = date.toUTCString()
    @pushRecord(result)
    return
  parsePage: (html) ->
  pushQueue: (result) ->
    if @seed.verdict(result)
      client.lpush(pushQueueKey, JSON.stringify(result))
    return
  pushRecord: (record) ->
    client.lpush(historyKey, JSON.stringify(record))
    return

class AmazonCNVisitor extends Visitor
  visit: ->
    self = this
    request(self.seed.url, (err, res, body) ->
      if err
        self.failRequestHandler(err, res)
      else if res.statusCode != 200
        self.errorResponseHandler(err, res)
      else
        self.parsePage(body)
      return
    )
    return
  
  failRequestHandler: (err, res) ->
  errorResponseHandler: (err, res) ->
  parsePage: (html) ->
    parser = selectParser(@seed.site)
    result = id: @seed.id, site: @seed.site, url: @seed.url
    for attr, val of parser.parse(html)
      result[attr] = val
    console.log(result)
    return result

class AmazonUSVisitor extends Visitor

class AmazonJPVisitor extends Visitor

class JingDongVisitor extends Visitor

module.exports.select = (seed) ->
  newVisitor =
    switch seed.site
      when "www.amazon.com" then new AmazonUSVisitor(seed)
      when "www.amazon.cn" then new AmazonCNVisitor(seed)
      when "www.amazon.co.jp" then new AmazonJPVisitor(seed)
      when "www.jd.com" then new JingDongVisitor(seed)
      else logger.warn(
        "there is no available visitor for site %s",
        seed.site)
  return newVisitor
