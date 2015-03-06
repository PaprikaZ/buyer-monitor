mkdirp = require('mkdirp')
path = require('path')
fs = require('fs')

appConfigFile = path.join(__dirname, '../config.json')
config = JSON.parse(fs.readFileSync(appConfigFile, 'utf8'))

runPath = path.join(__dirname, '../', config.runPath)
mkdirp.sync(runPath)

dbPath = path.join(__dirname, '../', config.databaseDataPath)
redisDataPath = path.join(dbPath, config.redisSubPath)
mongoDataPath = path.join(dbPath, config.mongoDBSubPath)
mkdirp.sync(dbPath)
mkdirp.sync(redisDataPath)
mkdirp.sync(mongoDataPath)

logPath = path.join(__dirname, '../', config.logPath)
logFile = path.join(logPath, config.logFileName)
mkdirp.sync(logPath)

logger = require('winston')
logger.add(logger.transports.File, {filename: logFile, level: config.loggerLevel})
global.logger = logger

module.exports = exports = config
