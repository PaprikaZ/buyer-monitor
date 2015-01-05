db = require('./db.js')
monitor = require('./monitor.js')

module.exports.launch = ->
  require('./argv_parser.js').parse(process.argv.slice(2), ->
    db.createClient()
    m = monitor.createMonitor().start()
    return
  )
  return
