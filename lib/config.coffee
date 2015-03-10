mkdirp = require('mkdirp')
path = require('path')
fs = require('fs')

appRoot = path.join(__dirname, '../')
appConfigFile = path.join(appRoot, 'config.json')
config = JSON.parse(fs.readFileSync(appConfigFile, 'utf8'))

config.runPath = path.join(appRoot, config.runPath)
config.redisPidFile = path.join(config.runPath, config.redisPidFile)
config.mongoPidFile = path.join(config.runPath, config.mongoPidFile)
mkdirp.sync(config.runPath)

config.dbPath = path.join(appRoot, config.databaseDataPath)
config.redisDataPath = path.join(config.dbPath, config.redisSubPath)
config.mongoDataPath = path.join(config.dbPath, config.mongoSubPath)
mkdirp.sync(config.redisDataPath)
mkdirp.sync(config.mongoDataPath)

config.redisConfFile = path.join(appRoot, config.redisConfFile)
config.mongoConfFile = path.join(appRoot, config.mongoConfFile)

config.logPath = path.join(appRoot, config.logPath)
config.logFile = path.join(config.logPath, config.logFileName)
mkdirp.sync(config.logPath)

logger = require('winston')
logger.add(logger.transports.File, {
  filename: config.logFile
  level: config.logLevel
})
global.logger = logger

module.exports = exports = config
