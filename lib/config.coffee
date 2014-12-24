path = require('path')
fs = require('fs')

config = JSON.parse(
  fs.readFileSync(path.join(__dirname, '../config.json'),
  'utf8'))

logger = require('winston')
logger.add(logger.transports.File, filename: config.logFile)
global.logger = logger

module.exports = config
