redis = require('redis')
mongoose = require('mongoose')
config = require('./config.js')

# Redis
redisClient = null

redisErrorRethrow = (err) ->
  logger.error('redis caught error')
  logger.error('msg: %s', err.message)
  throw err

exports.connectRedis = ->
  redisClient = redis.createClient(config.redisPort, config.redisHost)
  redisClient.select(config.redisDBIndex, (err, res) ->
    if err
      logger.error('redis select %s failed', config.redisDBIndex)
      redisErrorRethrow(err)
    else
      logger.debug('redis select %s %s', config.redisDBIndex, res)
    return
  )
  redisClient.on('error', (err) ->
    redisErrorRethrow(err)
    return
  )
  return

exports.getRedisClient = ->
  if redisClient
    return redisClient
  else
    logger.debug('redis client should be created just after monitor launched')
    throw new Error('redis client not initialized')

exports.clearQueue = -> redisClient.flushdb()
exports.redisErrorRethrow = redisErrorRethrow

# Mongo
mongoClient = null
mongoErrorRethrow = (err) ->
  logger.error('mongo caught error')
  logger.error('msg: %s', err.message)
  throw err

exports.connectMongoDB = ->
  mongoose.connect(config.mongoDBUrl, config.mongoConnectionOptions)

exports.getMongoClient = ->
  if mongoClient
    return mongoClient
  else
    logger.debug('mongo client should be created just adter monitor launched')
    throw new Error('mongo db client not initialized')

exports.mongoErrorRethrow = mongoErrorRethrow

module.exports = exports
