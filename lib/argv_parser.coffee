util = require('util')
fs = require('fs')
path = require('path')
config = require('./config.js')
productFile = path.join('./', config.productFileName)

unknownArgvHandler = ->
  console.log('Unknown arguments, please see help with "node app.js help"')
  process.exit()
  return

helpHandler = ->
  console.log('Usage:')
  console.log('  node app.js')
  console.log('    list')
  console.log('    add id <product-id> site <www.example.com> price under <target>')
  console.log('    remove id <product-id>')
  console.log('    reset')
  console.log('    help')
  console.log('')
  console.log('The most commonly used example:')
  console.log('')
  console.log('  List all existing products')
  console.log('  > node app.js list')
  console.log('  Also you can specify the id or site as to filter result')
  console.log('  > node app.js list site www.amazon.cn')
  console.log('  > node app.js list id B00JG8GOWU ')
  console.log('')
  console.log('  Add product id B00JG8GOWU on site www.amazon.com')
  console.log('  > node app.js add id B00JG8GOWU site www.amazon.com <require>')
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
  console.log('  > node app.js remove id B00JG8GOWU site www.amazon.com')
  console.log('  Since duplicated is merely happen, you ignore site option')
  console.log('  > node app.js remove id B00JG8GOWU')
  console.log('')
  console.log('  Reset all added products')
  console.log('  > node app.js reset')
  console.log('')
  console.log('  See this help page')
  console.log('  > node app.js help')
  console.log('')
  console.log('The monitor products located in product.json at root path.')
  process.exit()
  return

listHandler = ->
  console.log('Products monitored:')
  JSON.parse(fs.readFileSync(productFile)).forEach((elt, index, arr) ->
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
  console.log('list done.')
  process.exit()
  return

addHandler = (argv) ->
  writeRecord = (record) ->
    products = JSON.parse(fs.readFileSync(productFile))
    noDuplicatedProducts = products.filter((elt, index, arr) ->
      return elt.id != record.id or elt.site != record.site
    )
    
    if noDuplicatedProducts.length == products.length
      products.push(record)
      fs.writeFileSync(productFile, JSON.stringify(products))
      console.log('add done.')
    else
      noDuplicatedProducts.push(record)
      fs.writeFileSync(productFile, JSON.stringify(noDuplicatedProducts))
      console.log('product id %s, site %s update done.', record.id, record.site)
    process.exit()
    return

  analyze = ->
    record = {}
    priceIter = (remaining) ->
      if remaining[0] == 'under'
        record.price = {compare: 'under', target: parseInt(remaining[1])}
        return iter(remaining.slice(2))
      else
        unknownArgvHandler()
      return

    discountIter = (remaining) ->
      if remaining[0] == 'above'
        record.discount = {compare: 'above', target: parseInt(remaining[1])}
        return iter(remaining.slice(2))
      else
        unknownArgvHandler()
      return

    reviewIter = (remaining) ->
      if remaining[0] == 'above'
        record.review = {compare: 'above', target: remaining[1]}
        return iter(remaining.slice(2))
      else
        unknownArgvHandler()
      return

    benefitIter = (remaining) ->
      regex = /^\/(.*)\/(i?)$/
      if regex.test(remaining[0])
        matches = remaining[0].match(regex)
        record.benefit = {regex: matches[1], option: matches[2]}
        return iter(remaining.slice(1))
      else
        unknownArgvHandler()
      return

    iter = (remaining) ->
      if remaining.length == 0
        return record
      else if remaining[0] == 'id'
        record.id = remaining[1]
        iter(remaining.slice(2))
      else if remaining[0] == 'site'
        record.site = remaining[1]
        iter(remaining.slice(2))
      else if remaining[0] == 'price'
        priceIter(remaining.slice(1))
      else if remaining[0] == 'discount'
        discountIter(remaining.slice(1))
      else if remaining[0] == 'review'
        reviewIter(remaining.slice(1))
      else if remaining[0] == 'benefit'
        benefitIter(remaining.slice(1))
      else
        unknownArgvHandler()
      return

    iter(argv)
    if record.price or record.discount or record.benefit
      return record
    else
      unknownArgvHandler()
    return

  writeRecord(analyze())
  return

removeHandler = (argv) ->
  analyze = ->
    [id, site] = [false, false]
    iter = (remaining) ->
      if remaining.length == 0
        return [id, site]
      else if remaining[0] == 'id'
        id = remaining[1]
      else if remaining[0] == 'site'
        site = remaining[1]
      else
        unknownArgvHandler()
        return
      return iter(remaining.slice(2))
    return iter(argv)
  [id, site] = analyze()
  products = JSON.parse(fs.readFileSync(productFile))
  fs.writeFileSync(
    productFile,
    JSON.stringify(products.filter((elt, index, arr) ->
      if site
        return elt.id != id or elt.site != site
      else
        return elt.id != id
      )
    )
  )
  console.log('remove done.')
  process.exit()
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
      console.log('Invalid response, quit')
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
  return
