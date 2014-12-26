util = require('util')
request = require('request')
config = require('./config.js')
PARSE_FIELD = require('./page_parser.js').MANDATORY_FIELD
PRODUCT_BASE_FIELD = require('./seed.js').MANDATORY_BASE_FIELD

accessTokens = config.accounts.map((account) ->
  return account.accessToken)

assembleMessageTitle = (result) ->
  if PRODUCT_BASE_FIELD.reduce(((partial, field) -> return partial and result[field]), true)
    title = util.format('id %s on site %s meet your requirement', result.id, result.site)
  else
    logger.error('there is product base field missing')
    resultErrorHandler()
  return title

assembleMessageBody = (result) ->
  if PARSE_FIELD.reduce(((partial, field) -> return partial and result[field]), true)
    body =  util.format('Title: %s\n', result.title)
    body += util.format('Url: %s\n', result.url)
    body += util.format('Price: %s        full price: %s\n', result.price, result.fullPrice)
    body += util.format('Discount: %s\% OFF\n', Math.round(result.discount))
    body += util.format('Review: %s\n', result.review)
    body += util.format('Instore: %s\n', (result.instore? 'yes' : 'no'))
    if 0 < result.benefits.length
      result.benefits.forEach((benefit, idx) ->
        body += util.format('Benefit%s: %s\n', idx, benefit)
        return
      )
    else
      body += 'Benefits: none\n'
  else
    logger.error('there is parse field missing')
    resultErrorHandler()
  return body

push = (result) ->
  logger.debug('id %s site %s ready to be pushed', result.id, result.site)
  if 0 < accessTokens.length
    messenge =
      type: 'note'
      title: assembleMessageTitle(result)
      body: assembleMessageBody(result)

    accessTokens.map((token) ->
      shortToken = token.slice(0, 7)
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
    )
  else
    logger.error('no available tokens')
    tokenEmptyHandler()
  return

tokenEmptyHandler = ->
  throw new Error('no available tokens')

resultErrorHandler = ->
  throw new Error('result attributes error')

responseErrorHandler = (token, res, body) ->
  logger.error('http post response error.')
  logger.error('token %s response status code: %s', token, res.statusCode)
  logger.error('token %s body: %s', token, body)
  throw new Error('push message response error')

requestErrorHandler = (token, err) ->
  logger.error('http post request error.')
  logger.error('token %s, error %s', token, err.message)
  throw err

module.exports.push = push
