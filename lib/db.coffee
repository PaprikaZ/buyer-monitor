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

exports.clearQueue = -> client.flushdb()
exports.redisErrorRethrow = redisErrorRethrow
module.exports = exports
