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
  return

module.exports.getClient = ->
  if client
    return client
  else
    logger.debug('database client should be created just after monitor launched')
    throw new Error('client not initialized')

module.exports.clearQueue = ->
  client.del(config.redisPushQueueKey, (err, res) ->
    if err
      logger.error('clear push queue %s failed', config.redisPushQueueKey)
      logger.error('%s', err.message)
      throw err
    else
      logger.debug('clear push queue response: %s', res)
    return
  )

  client.del(config.redisPullQueueKey, (err, res) ->
    if err
      logger.error('clear pull queue %s failed', config.redisPullQueueKey)
      logger.error('%s', err.message)
      throw err
    else
      logger.debug('clear pull queue response: %s', res)
    return
  )
  return
