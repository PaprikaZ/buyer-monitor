redis = require('redis')
config = require('./config.js')
redisRecordDBIndex = config.redisRecordDBIndex

module.exports = ->
  client = redis.createClient(config.redisPort, config.redisHost)
  client.select(redisRecordDBIndex, (err, res) ->
    if err
      logger.error("redis select %s failed, %s", redisRecordDBIndex, err)
    else
      logger.debug("redis select %s %s", redisRecordDBIndex, res)
    return
  )
  client.on("error", (err) ->
    logger.error("visitor record client caught error, %s", err)
    return
  )
  logger.debug("redis record client connect success")
  return client
