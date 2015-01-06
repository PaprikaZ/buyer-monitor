util = require('util')
request = require('request')
config = require('./config.js')
MANDATORY_PARSE_FIELDS = require('./page_parser.js').MANDATORY_FIELDS
SEED_BASE_FIELDS = require('./seed.js').MANDATORY_BASE_FIELDS

assembleMessageTitle = (result) ->
  title = ''

  if SEED_BASE_FIELDS.every((field) -> result[field])
    SEED_BASE_FIELDS.map((field) ->
      title += util.format(', %s %s', field, result[field])
      return
    )
    title += ' meet your requirements'
  else
    fieldMissingHandler(SEED_BASE_FIELDS.join(' or '))
  return title.slice(2)

assembleMessageBody = (result) ->
  body = ''

  if MANDATORY_PARSE_FIELDS.every((field) -> result[field])
    MANDATORY_PARSE_FIELDS.map((field) ->
      if Array.isArray(result[field])
        body += util.format('%s:\n', field)
        result[field].map((item) ->
          body += util.format('  %s', item)
          return
        )
      else if field == 'discount'
        body += util.format('%s: %s\n', field, Math.round(result[field]))
      else
        body += util.format('%s: %s\n', field, result[field])
      return
    )
  else
    fieldMissingHandler(MANDATORY_PARSE_FIELDS.join(' or '))
  return body

shortenToken = (token) -> token.slice(0, 7)
push = (result, token) ->
  debugMsg = ''
  SEED_BASE_FIELDS.map((field) ->
    debugMsg += util.format('%s %s', field, result[field])
    return
  )
  debugMsg += 'ready to be pushed'
  logger.debug(debugMsg)

  shortToken = shortenToken(token)
  messenge =
    type: 'note'
    title: assembleMessageTitle(result)
    body: assembleMessageBody(result)
  postOptions =
    url: config.pushServiceUrl
    auth:
      user: token
    headers:
      'content-type': 'application/json'
    body: JSON.stringify(messenge)

  request.post(postOptions, (err, res, body) ->
    if not err
      if res.statusCode == 200
        logger.info('push message to user %s ok.', shortToken)
      else
        responseErrorHandler(shortToken, res, body)
    else
      requestErrorHandler(shortToken, err)
    return
  )
  return

fieldMissingHandler = (fields) ->
  logger.error('%s is missing', fields)
  throw new Error('data error, missing necessary fields')

responseErrorHandler = (token, res, body) ->
  logger.error('http post response error.')
  logger.error('%s url: %s', token, res.url)
  logger.error('%s status code: %s', token, res.statusCode)
  logger.error('%s body: %s', token, body)
  throw new Error('push message response error')

requestErrorHandler = (token, err) ->
  logger.error('http post request error.')
  logger.error('%s, error %s', token, err.message)
  throw err

module.exports = exports = push
