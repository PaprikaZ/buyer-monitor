site = require('./site.js')
config = require('./config.js')

MANDATORY_BASE_FIELDS = ['id', 'site']
AVAILABLE_VERDICT_FIELDS = ['price', 'discount', 'instore', 'review', 'benefits']
AVAILABLE_METHODS = ['above', 'under', 'equal', 'match']
_AVAILABLE_VERDICT_METHODS = AVAILABLE_VERDICT_FIELDS.map((field) ->
  return 'verdict' + field.slice(0, 1).toUpperCase() + field.substring(1)
)

_FIELDS_EXPAND_TABLE =
  url: site.generateProductUrl
  currency: (i, s) -> site.getSiteCurrency(s)
  encoding: (i, s) -> site.getSiteEncoding(s)
MANDATORY_EXPAND_FIELDS = []
for field, expand of _FIELDS_EXPAND_TABLE
  MANDATORY_EXPAND_FIELDS.push(field)

illegalTypeHandler = (id, site, field) ->
  logger.error('id %s site %s %s verdict with a illegal value', id, site, field)
  throw new Error('value not support error, illegal verdict value')

verdictMissingHandler = (id, site) ->
  logger.error('id %s site %s missing verdict field', id, site)
  throw new Error('value missing error, non verdict fields specified')

noneVerdictLoadedHandler = (id, site) ->
  logger.error('id %s site %s none verdict loaded', id, site)
  throw new Error('load error, none verdict fields loaded')

class Seed
  constructor: (verdict) ->
    self = @
    MANDATORY_BASE_FIELDS.map((field) -> self[field] = verdict[field])
    for field, expand of _FIELDS_EXPAND_TABLE
      @[field] = expand.apply(
        null, MANDATORY_BASE_FIELDS.map((field) -> verdict[field]))

    (->
      verdictLoaded = false
      AVAILABLE_VERDICT_FIELDS.map((field) ->
        if verdict[field]
          if verdict[field].target != 'null'
            self[field] = verdict[field]
            verdictLoaded = true
          else
            illegalTypeHandler(verdict.id, verdict.site, field)
        return
      )
      not verdictLoaded and verdictMissingHandler(verdict.id, verdict.site)
      return
    )()

    if verdict.price
      @verdictPrice = (x) ->
        return x.price < verdict.price.target

    if verdict.discount
      @verdictDiscount = (x) ->
        return verdict.discount.target < x.discount

    if verdict.review
      @verdictReview = (x) ->
        return verdict.review.target < x.review

    if verdict.instore
      @verdictInstore = (x) ->
        return x.instore == verdict.instore

    if verdict.benefits
      regex = new RegExp(verdict.benefits.regex, verdict.benefits.option)
      @verdictBenefits = (x) ->
        return x.benefits.some((elt) -> return regex.test(elt))

    _AVAILABLE_VERDICT_METHODS.some((verdict) -> self[verdict]) or
      noneVerdictLoadedHandler(verdict.id, verdict.site)

    return

  verdict: (result) ->
    self = @
    return _AVAILABLE_VERDICT_METHODS
      .filter((method) ->
        return self[method]
      )
      .every((method) ->
        return self[method](result)
      )

  equal: (seed) ->
    self = @
    return MANDATORY_BASE_FIELDS.every((field) ->
      return self[field] == seed[field]
    )

exports.Seed = Seed
exports.MANDATORY_BASE_FIELDS = MANDATORY_BASE_FIELDS
exports.MANDATORY_EXPAND_FIELDS = MANDATORY_EXPAND_FIELDS
exports.AVAILABLE_VERDICT_FIELDS = AVAILABLE_VERDICT_FIELDS
exports.AVAILABLE_METHODS = AVAILABLE_METHODS
module.exports = exports
