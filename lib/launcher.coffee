db = require('./db.js')
monitor = require('./monitor.js')

module.exports.launch = ->
  require('./argv_parser.js').parse(process.argv.slice(2), ->
    process.on('SIGINT', ->
      logger.info('Caught SIGINT, try teardown redis and mongodb instance')
      db.stopDBService()
      setTimeout((-> process.exit(1)), 1000)
      return
    )
    db.startDBService()

    setTimeout((->
      db.connectRedis()
      db.clearQueue()
      db.connectMongoDB()
      monitor.createMonitor().start()
      return
    ), 1000)
    return
  )
  return
