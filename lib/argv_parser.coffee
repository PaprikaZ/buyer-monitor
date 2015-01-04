util = require('util')
fs = require('fs')
path = require('path')
seed = require('./seed.js')
AVAILABLE_COMPARES = seed.AVAILABLE_COMPARES
MANDATORY_BASE_FIELDS = seed.MANDATORY_BASE_FIELDS
MANDATORY_VERDICT_FIELDS = seed.MANDATORY_VERDICT_FIELDS
config = require('./config.js')
productFile = path.join('./', config.productFileName)

unknownArgvHandler = ->
  throw new Error('Unknown arguments, please see help with "node main.js help"')

lackArgHandler = ->
  throw new Error('Lack of arguments, please see help with "node main.js help"')

helpHandler = ->
  console.log('Usage:')
  console.log('  node main.js')
  console.log('    list')
  console.log('    add id <product-id> site <www.example.com> price under <target>')
  console.log('    remove id <product-id>')
  console.log('    reset')
  console.log('    help')
  console.log('')
  console.log('The most commonly used example:')
  console.log('')
  console.log('  List all existing products')
  console.log('  > node main.js list')
  console.log('  Also you can specify the id or site as to filter result')
  console.log('  > node main.js list site www.amazon.cn')
  console.log('  > node main.js list id B00JG8GOWU ')
  console.log('')
  console.log('  Add product id B00JG8GOWU on site www.amazon.com')
  console.log('  > node main.js add id B00JG8GOWU site www.amazon.com <require>')
  console.log('    About the requirement, some operation is given')
  console.log('    Those price under 12 (according local) will be noticed')
  console.log('    > price under 12')
  console.log('')
  console.log('    Those discount above 20% will be noticed')
  console.log('    > price discount above 0.8')
  console.log('    > price discount above 20')
  console.log('')
  console.log('    And user review based on five star convention')
  console.log('    > review above four star')
  console.log('    > review above four-half star')
  console.log('')
  console.log('    Also benefits match available, support regex')
  console.log('    > benefits /buy two with one off/')
  console.log('')
  console.log('  Remove product id B00JG8GOWU')
  console.log('  > node main.js remove id B00JG8GOWU site www.amazon.com')
  console.log('  Since duplicated is merely happen, you ignore site option')
  console.log('  > node main.js remove id B00JG8GOWU')
  console.log('')
  console.log('  Reset all added products')
  console.log('  > node main.js reset')
  console.log('')
  console.log('  See this help page')
  console.log('  > node main.js help')
  console.log('')
  console.log('The monitor products located in product.json at root path.')
  process.exit()
  return

listHandler = ->
  console.log('Products monitored:')
  products = JSON.parse(fs.readFileSync(productFile))
  if 0 < products.length
    products.forEach((product) ->
      output = ''
      MANDATORY_BASE_FIELDS.map((field) ->
        output += util.format(', %s %s', field, product[field])
        return
      )
      MANDATORY_VERDICT_FIELDS.map((field) ->
        if product[field]
          if product[field].compare == 'equal'
            output += util.format(
              ', %s? %s', field, product[field].target)
          else if field == 'benefits' and product[field].compare == 'match'
            output += util.format(
              ', benefits match \/%s\/%s', product[field].regex, product[field].option)
          else
            output += util.format(
              ', %s %s', field, product[field].target)
        return
      )
      output = output.slice(2)
      console.log(output)
      return
    )
  else
    console.log('empty')
  console.log('\nlist done.')
  process.exit()
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
        lackArgHandler()
      return

    iter = (remaining) ->
      if remaining.length == 0
        return record
      else if remaining[0] == 'id'
        if 1 < remaining.length
          record.id = remaining[1]
          iter(remaining.slice(2))
        else
          lackArgHandler()
      else if remaining[0] == 'site'
        if 1 < remaining.length
          record.site = remaining[1]
          iter(remaining.slice(2))
        else
          lackArgHandler()
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
    if MANDATORY_BASE_FIELDS.every((field) -> return record[field]) and MANDATORY_VERDICT_FIELDS.some((field) -> return record[field])
      return record
    else
      lackArgHandler()
    return

  writeRecord = (record) ->
    products = JSON.parse(fs.readFileSync(productFile))
    filteredProducts = products.filter((elt, index, arr) ->
      return elt.id != record.id or elt.site != record.site
    )
    filteredProducts.push(record)
    fs.writeFileSync(productFile, JSON.stringify(filteredProducts))
    if filteredProducts.length == products.length
      console.log('id %s, site %s update done.', record.id, record.site)
    else
      console.log('add done.')
    return

  writeRecord(analyze())
  process.exit()
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
        lackArgHandler()
      else
        unknownArgvHandler()
      return iter(remaining.slice(2))
    return iter(argv)
  [id, site] = analyze()
  if id != false
    products = JSON.parse(fs.readFileSync(productFile))
    filteredProducts = products.filter((elt, index, arr) ->
      if site
        return elt.id != id or elt.site != site
      else
        return elt.id != id
    )
    if filteredProducts.length < products.length
      fs.writeFileSync(productFile, JSON.stringify(filteredProducts))
      console.log('remove done.')
      process.exit()
    else
      if site
        msg = util.format('id %s site %s not founded!', id, site)
        throw new Error(msg)
      else
        msg = util.format('id %s not founded!', id)
        throw new Error(msg)
  else
    lackArgHandler()
  return

resetHandler = ->
  process.stdout.write('Are you sure to reset product data? [yes/no] ')
  process.stdin.setEncoding('utf8')
  process.stdin.once('data', (input) ->
    input = input.trim().toLowerCase()
    if input == 'y' or input == 'yes'
      fs.writeFileSync(productFile, JSON.stringify([]))
    else if input == 'n' or input == 'no'
      console.log('Reset aborted by user')
    else
      throw new Error('Invalid response, quit')
    return process.exit()
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
