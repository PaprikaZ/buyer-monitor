fs = require('fs')
spawn = require('child_process').spawn
redis = require('redis')
mongoose = require('mongoose')
config = require('./config.js')

# DB paths
exports.startDBService = ->
  logger.info('starting redis/mongodb service')
  try
    fs.unlinkSync(config.redisPidFile)
    fs.unlinkSync(config.mongoPidFile)
  catch err
  finally
    spawn(config.redisCommand, [config.redisConfFile])
    spawn(config.mongoCommand, ['-f', config.mongoConfFile])
  return

exports.stopDBService = ->
  logger.info('stopping redis/mongodb service')
  redisClient.quit()
  mongoose.disconnect()
  setTimeout((->
    spawn('pkill', ['--pidfile', config.redisPidFile])
    spawn('pkill', ['--pidfile', config.mongoPidFile])
    return
  ), 500)
  try
    fs.unlinkSync(config.mongoPidFile)
  catch err
    logger.warn('mongod is already stopped')
  return

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
  mongoClient = mongoose.connect(config.mongoDBUrl, config.mongoConnectionOptions)
  return

exports.getMongoClient = ->
  if mongoClient
    return mongoClient
  else
    logger.debug('mongo client should be created just adter monitor launched')
    throw new Error('mongo db client not initialized')

exports.mongoErrorRethrow = mongoErrorRethrow

module.exports = exports
