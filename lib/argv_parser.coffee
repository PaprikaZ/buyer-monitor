util = require('util')
fs = require('fs')
path = require('path')
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
  console.log('    Also benefit available, support regex')
  console.log('    > benefit /buy two with one off/')
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
    products.forEach((elt, index, arr) ->
      output = util.format('id %s site %s ', elt.id, elt.site)
      if elt.price
        output += util.format( 'price %s %s ', elt.price.compare, elt.price.target)
      if elt.discount
        output += util.format(
          'discount %s %s\%off ', elt.discount.compare, elt.discount.target)
      if elt.review
        output += util.format(
          'review %s %s ', elt.review.compare, elt.review.target)
      if elt.benefit
        output += util.format(
          'benefit match \/%s\/%s',
          elt.benefit.regex, elt.benefit.option)
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
    keywordIter = (remaining, compareKeyword, parse) ->
      if 1 < remaining.length and remaining[0] == compareKeyword
        record.price = {compare: remaining[0], target: parse(remaining[1])}
        return iter(remaining.slice(2))
      else if remaining.length < 2
        lackArgHandler()
      else
        unknownArgvHandler()
      return

    benefitIter = (remaining) ->
      regex = /^\/(.*)\/(i?)$/
      if 0 < remaining.length and remaining.regex.test(remaining[0])
        matches = remaining[0].match(regex)
        record.benefit = {regex: matches[1], option: matches[2]}
        return iter(remaining.slice(1))
      else if remaining.length < 1
        lackArgHandler()
      else
        unknownArgvHandler()
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
        keywordIter(remaining.slice(1), 'under', parseInt)
      else if remaining[0] == 'discount'
        keywordIter(remaining.slice(1), 'above', parseInt)
      else if remaining[0] == 'review'
        keywordIter(remaining.slice(1), 'above', (x) -> x)
      else if remaining[0] == 'benefit'
        benefitIter(remaining.slice(1))
      else
        unknownArgvHandler()
      return

    iter(argv)
    if record.id and record.site and (record.price or record.discount or record.benefit)
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
      console.log('add done.')
    else
      console.log('id %s, site %s update done.', record.id, record.site)
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
