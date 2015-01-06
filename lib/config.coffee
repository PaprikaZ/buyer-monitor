mkdirp = require('mkdirp')
path = require('path')
fs = require('fs')

config = JSON.parse(
  fs.readFileSync(path.join(__dirname, '../config.json'),
  'utf8'))

logDirectory = path.join(__dirname, '../log')
logFile = path.join(logDirectory, config.logFileName)
mkdirp.sync(logDirectory)

logger = require('winston')
logger.add(logger.transports.File, {filename: logFile, level: config.loggerLevel})
global.logger = logger

module.exports = config
