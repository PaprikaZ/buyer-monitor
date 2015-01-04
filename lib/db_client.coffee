redis = require('redis')
config = require('./config.js')
redisRecordDBIndex = config.redisRecordDBIndex

client = null

module.exports.createClient = ->
  client = redis.createClient(config.redisPort, config.redisHost)
  client.select(redisRecordDBIndex, (err, res) ->
    if err
      logger.error('redis select %s failed', redisRecordDBIndex)
      throw err
    else
      logger.debug('redis select %s %s', redisRecordDBIndex, res)
    return
  )
  client.on('error', (err) ->
    logger.error('visitor record client caught error')
    throw err
    return
  )
  logger.debug('redis record client connect success')
  return

module.exports.getClient = ->
  if client
    return client
  else
    logger.debug('database client should be created just after monitor launched')
    throw new Error('client not initialized')
