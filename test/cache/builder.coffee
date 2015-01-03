fs = require('fs')
path = require('path')
crypto = require('crypto')
request = require('request')
parsedProductsData = JSON.parse(fs.readFileSync(
  path.join(__dirname, './product.json')))
hashAlgorithm = parsedProductsData.hashAlgorithm
digestEncoding = parsedProductsData.digestEncoding
products = parsedProductsData.products
htmlTableFile = path.join(__dirname, './html.json')

clean = ->
  htmlFiles = fs.readdirSync(__dirname).filter((filename) ->
    return /\.html$/.test(filename)
  )
  htmlFiles.map((filename) ->
    fs.unlink(path.join(__dirname, filename))
    return
  )
  try
    fs.closeSync(fs.openSync(htmlTableFile, 'r'))
    fs.unlink(htmlTableFile)
  catch err
    if not (err.errno == 34 and err.code == 'ENOENT')
      throw err
  finally
    console.log('clean done.')
  return

build = ->
  clean()

  makeRequestCallback = ->
    urlToHtmlTable = {}
    counter = products.length

    afterCallbacksDone = ->
      fs.writeFileSync(htmlTableFile, JSON.stringify(urlToHtmlTable))
      return

    callback = (err, res, body, url) ->
      if not err and res.statusCode == 200
        md5sum = crypto.createHash(hashAlgorithm)
        fileName = md5sum.update(url).digest(digestEncoding) + '.html'
        fs.writeFileSync(path.join(__dirname, fileName), body)
        urlToHtmlTable[url] = fileName
      else if err
        throw err
      else
        console.error('response caught error:')
        console.error('url: %s', res.url)
        console.error('status code: %s', res.statusCode)
      return

    return (err, res, body, url) ->
      callback(err, res, body, url)
      counter = counter - 1
      if counter == 0
        afterCallbacksDone()
      return
  requestCallback = makeRequestCallback()

  req = (url, callback) ->
    request(url, (err, res, body) -> callback(err, res, body, url))
  products.map((item) -> item.url).map((url) ->
    req(url, requestCallback)
    return
  )
  return

help = ->
  console.log('Help:')
  console.log('> node builder.js build')
  console.log('clean and build new cached pages from product.json')
  console.log('')
  console.log('> node builder.js clean')
  console.log('clean already cached page files *.html')
  console.log('')
  console.log('> node builder.js help')
  console.log('print this help message')
  return

main = ->
  argv = process.argv.slice(2)
  if argv.length == 1
    switch argv[0]
      when 'build' then build()
      when 'clean' then clean()
      when 'help' then help()
      else
        console.error('error: unknown command')
        help()
  else
    console.error('error: unknown commands')
    help()
  return

if require.main == module
  main()
