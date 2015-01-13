redis = require('redis')
config = require('./config.js')
redisRecordDBIndex = config.redisRecordDBIndex

client = null

redisErrorRethrow = (err) ->
  logger.error('redis database caught error')
  logger.error('msg: %s', err.message)
  throw err

exports.createClient = ->
  client = redis.createClient(config.redisPort, config.redisHost)
  client.select(redisRecordDBIndex, (err, res) ->
    if err
      logger.error('redis select %s failed', redisRecordDBIndex)
      redisErrorRethrow(err)
    else
      logger.debug('redis select %s %s', redisRecordDBIndex, res)
    return
  )
  client.on('error', (err) ->
    redisErrorRethrow(err)
    return
  )
  return

exports.getClient = ->
  if client
    return client
  else
    logger.debug('database client should be created just after monitor launched')
    throw new Error('client not initialized')

exports.clearQueue = ->
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
exports.redisErrorRethrow = redisErrorRethrow
module.exports = exports
