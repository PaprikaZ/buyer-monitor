util = require('util')
fs = require('fs')
path = require('path')

_seed = require('./seed.js')
AVAILABLE_COMPARES = _seed.AVAILABLE_COMPARES
MANDATORY_BASE_FIELDS = _seed.MANDATORY_BASE_FIELDS
AVAILABLE_VERDICT_FIELDS = _seed.AVAILABLE_VERDICT_FIELDS

config = require('./config.js')
verdictsFileName = path.join(__dirname, '../', config.verdictsFileName)

illegalValueHandler = (field) ->
  console.error('illegal arguments, field %s', field)
  throw new Error('input error, illegal value')

unknownArgvHandler = ->
  console.error('unknown arguments, please see help with "node app.js help"')
  throw new Error('input error, unknown arguments')

missingArgHandler = ->
  console.error('missing arguments, please see help with "node app.js help"')
  throw new Error('input error, missing arguments')

verdictNotFoundHandler = (id, site) ->
  console.error('verdict id %s site %s not found', id, site)
  console.error('please check with "node app.js list"')
  throw new Error('input error, verdict not founded')

invalidResponseHandler = (res) ->
  console.error('invalid response %s', res)
  throw new Error('input error, invalid response')

helpHandler = ->
  console.log('Usage:')
  console.log('  node app.js')
  console.log('    list')
  console.log('    add id <id> site <site> [<verdict> <compare> <target>] ...')
  console.log('    remove id <id> site <site>')
  console.log('    reset')
  console.log('    help')
  console.log('')
  console.log('  list all existing verdict records')
  console.log('  > node app.js list')
  console.log('')
  console.log('  add product id B00JG8GOWU site www.example.com with price verdict')
  console.log('  > node app.js add id B00JG8GOWU site www.example.com <verdict ...>')
  console.log('    once price under 12 will be pushed')
  console.log('    > price under 12')
  console.log('')
  console.log('    once discount above 20% will be pushed')
  console.log('    > price discount above 20')
  console.log('')
  console.log('    once review above 8 will be pushed')
  console.log('    > review above 8')
  console.log('')
  console.log('    once instored will be pushed')
  console.log('    > instore yes')
  console.log('')
  console.log('    once benefits match regexp will be pushed')
  console.log('    > benefits /buy two with one off/i')
  console.log('')
  console.log('    available verdicts:')
  console.log('    price, discount, review, instore, benefits')
  console.log('    available compare:')
  console.log('    under, above')
  console.log('')
  console.log('  remove product id B00JG8GOWU on site www.example.com')
  console.log('  > node app.js remove id B00JG8GOWU site www.amazon.com')
  console.log('')
  console.log('  reset all verdict records')
  console.log('  > node app.js reset')
  console.log('')
  console.log('  to see help page')
  console.log('  > node app.js help')
  console.log('')
  console.log('The verdicts records located in verdicts.json at application root.')
  return

listHandler = ->
  console.log('Products verdicted:')
  verdicts = JSON.parse(fs.readFileSync(verdictsFileName))
  if 0 < verdicts.length
    verdicts.forEach((verdict) ->
      output = ''
      MANDATORY_BASE_FIELDS.map((field) ->
        output += util.format(', %s %s', field, verdict[field])
        return
      )
      AVAILABLE_VERDICT_FIELDS.map((field) ->
        if verdict[field]
          if verdict[field].compare == 'equal'
            output += util.format(
              ', %s? %s', field, verdict[field].target)
          else if field == 'benefits' and verdict[field].compare == 'match'
            output += util.format(
              ', benefits match \/%s\/%s', verdict[field].target.regex, verdict[field].target.option)
          else
            output += util.format(
              ', %s %s %s', field, verdict[field].compare, verdict[field].target)
        return
      )
      output = output.slice(2)
      console.log(output)
      return
    )
  else
    console.log('empty')
  console.log('\nlist done.')
  return

addHandler = (argv) ->
  analyze = ->
    record = {}
    keywordIter = (remaining, parse) ->
      if 1 < remaining.length
        if AVAILABLE_COMPARES.indexOf(remaining[0]) != -1
          return {
            compare: remaining[0]
            target: parse(remaining[1])
          }
        else
          unknownArgvHandler()
      else
        missingArgHandler()
      return

    iter = (remaining) ->
      if remaining.length == 0
        return
      else if remaining[0] == 'id'
        if 1 < remaining.length
          if /^[0-9a-zA-Z]+$/.test(remaining[1])
            record.id = remaining[1]
            iter(remaining.slice(2))
          else
            illegalValueHandler('id')
        else
          missingArgHandler()
      else if remaining[0] == 'site'
        if 1 < remaining.length
          if /^www\.\w+(\.\w{2,3}){1,2}$/.test(remaining[1])
            record.site = remaining[1]
            iter(remaining.slice(2))
          else
            illegalValueHandler('site')
        else
          missingArgHandler()
      else if remaining[0] == 'price'
        record.price = keywordIter(remaining.slice(1, 3), parseInt)
        iter(remaining.slice(3))
      else if remaining[0] == 'discount'
        record.discount = keywordIter(remaining.slice(1, 3), parseInt)
        iter(remaining.slice(3))
      else if remaining[0] == 'review'
        record.review = keywordIter(remaining.slice(1, 3), parseInt)
        iter(remaining.slice(3))
      else if remaining[0] == 'instore'
        record.instore = keywordIter(['equal'].concat(remaining.slice(1, 2)), (x) ->
          switch x
            when 'yes' then return true
            when 'y' then return true
            when 'no' then return false
            when 'n' then return false
            else unknownArgvHandler()
        )
        iter(remaining.slice(2))
      else if remaining[0] == 'benefits'
        record.benefits = keywordIter(['match'].concat(remaining.slice(1, 2)), (x) ->
          regex = /^\/(.*)\/(i?)$/
          matches = x.match(regex)
          return {regex: matches[1], option: matches[2]}
        )
        iter(remaining.slice(2))
      else
        unknownArgvHandler()
      return

    iter(argv)
    if MANDATORY_BASE_FIELDS.every((field) -> return record[field]) and AVAILABLE_VERDICT_FIELDS.some((field) -> return record[field])
      return record
    else
      missingArgHandler()
    return

  writeRecord = (record) ->
    verdicts = JSON.parse(fs.readFileSync(verdictsFileName))
    filteredVerdicts = verdicts.filter((elt) ->
      return elt.id != record.id or elt.site != record.site
    )
    filteredVerdicts.push(record)
    fs.writeFileSync(verdictsFileName, JSON.stringify(filteredVerdicts))
    if filteredVerdicts.length == verdicts.length
      console.log('id %s, site %s update done.', record.id, record.site)
    else
      console.log('add done.')
    return

  writeRecord(analyze())
  return

removeHandler = (argv) ->
  analyze = ->
    [id, site] = [false, false]
    iter = (remaining) ->
      if remaining.length == 0
        return [id, site]
      else if 1 < remaining.length and remaining[0] == 'id'
        id = remaining[1]
      else if 1 < remaining.length and remaining[0] == 'site'
        site = remaining[1]
      else if remaining.length < 2
        missingArgHandler()
      else
        unknownArgvHandler()
      return iter(remaining.slice(2))
    return iter(argv)
  [id, site] = analyze()
  if id and site
    verdicts = JSON.parse(fs.readFileSync(verdictsFileName))
    filteredVerdicts = verdicts.filter((elt) ->
      return elt.id != id or elt.site != site
    )
    if filteredVerdicts.length < verdicts.length
      fs.writeFileSync(verdictsFileName, JSON.stringify(filteredVerdicts))
      console.log('remove done.')
    else
      verdictNotFoundHandler(id, site)
  else
    missingArgHandler()
  return

resetHandler = ->
  process.stdout.write('Are you sure to reset product data? [yes/no] ')
  process.stdin.setEncoding('utf8')
  process.stdin.once('data', (input) ->
    input = input.trim().toLowerCase()
    if input == 'y' or input == 'yes'
      fs.writeFileSync(verdictsFileName, JSON.stringify([]))
    else if input == 'n' or input == 'no'
      console.log('reset aborted by user')
    else
      invalidResponseHandler(input)
    process.stdin.emit('end')
    return
  )
  return

module.exports.parse = (argv, launch) ->
  if argv.length == 0
    launch()
  else if argv[0] == 'add' and 1 < argv.length
    addHandler(argv.slice(1))
  else if argv[0] == 'remove' and 1 < argv.length
    removeHandler(argv.slice(1))
  else if argv[0] == 'list' and argv.length == 1
    listHandler()
  else if argv[0] == 'reset' and argv.length == 1
    resetHandler()
  else if argv[0] == 'help' and argv.length == 1
    helpHandler()
  else
    unknownArgvHandler()
  return
