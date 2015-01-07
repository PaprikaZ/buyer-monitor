request = require('request')
config = require('./config.js')

verificationDone = false
validTokens = []
shortenToken = (token) -> token.slice(0, 7)

exports.verify = (tokens) ->
  logger.info('user access tokens verifying ...')
  problemTokens = []
        
  makeVerifyDone = ->
    counter = tokens.length
    return ->
      counter -= 1
      if counter == 0
        logger.info('all access tokens verification done.')
        validTokens = tokens.filter((token) ->
          return problemTokens.indexOf(token) == -1
        )
        if validTokens.length != 0
          verificationDone = true
        else
          throw new Error('config error, all token invalid')
      return
  verifyDone = makeVerifyDone()

  tokens.map((token) ->
    shortToken = shortenToken(token)
    options =
      url: config.userServiceUrl
      auth:
        user: token

    request.get(options, (err, res, body) ->
      if not err
        if res.statusCode == 200
          logger.debug('token %s verify ok', shortToken)
        else
          logger.warn('token %s is invalid', shortToken)
          logger.warn('%s url: %s', shortToken, res.url)
          logger.warn('%s status code: %s', shortToken, res.statusCode)
          logger.warn('%s message: %s', shortToken, body)
          problemTokens.push(token)
          logger.info('%s removed from subscribers', shortToken)
      else
        logger.error('token %s verify caught request error.', shortToken)
        logger.error('%s error: %s', shortToken, err.message)
        problemTokens.push(token)
        logger.info('%s removed from subscribers', shortToken)

      verifyDone()
      return
    )
    return
  )
  return
exports.isVerificationDone = -> verificationDone
exports.getValidTokens = -> validTokens
module.exports = exports
