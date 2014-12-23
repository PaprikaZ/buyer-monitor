redis = require("redis")
config = rootRequire("src/config.js")
redisPort = config.redisPort
redisHost = config.redisHost
redisRecordDBIndex = config.redisRecordDBIndex

module.exports.newClient = ->
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
  return client
