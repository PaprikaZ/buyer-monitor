path = require('path')
fs = require('fs')

config = JSON.parse(
  fs.readFileSync(path.join(__dirname, '../config.json'),
  'utf8'))
logDirectory = './log'
logFile = path.join(logDirectory, config.logFileName)
not fs.existsSync(logDirectory) and fs.mkdirSync(logDirectory)

logger = require('winston')
logger.add(logger.transports.File, {filename: logFile})
global.logger = logger

module.exports = config
