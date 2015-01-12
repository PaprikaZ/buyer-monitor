fs = require('fs')
path = require('path')
crypto = require('crypto')
request = require('request')
mkdirp = require('mkdirp')
iconv = require('iconv-lite')
seed = require('../../lib/seed.js')
site = require('../../lib/site.js')
htmlTableFile = path.join(__dirname, './html.json')

configFile = path.join(__dirname, './config.json')
config = JSON.parse(fs.readFileSync(configFile))
htmlDirectory = path.join(__dirname, config.htmlDirectory)
hashAlgorithm = config.hashAlgorithm
digestEncoding = config.digestEncoding

cacheItemToProduct = (item) ->
  product = {}
  mountField = (field) ->
    product[field] = item[field]
    return

  seed.MANDATORY_BASE_FIELDS.map(mountField)
  config.extraFields.map(mountField)
  product.url = site.generateProductUrl(product.id, product.site)
  return product

cacheItemToVerdict = (item) ->
  verdict = {}

  seed.MANDATORY_BASE_FIELDS.map((field) ->
    verdict[field] = item[field]
    return
  )
  seed.AVAILABLE_VERDICT_FIELDS.map((field) ->
    if item[field]
      verdict[field] = item[field]
    return
  )
  return verdict

clean = ->
  mkdirp.sync(htmlDirectory, '0774')
  htmlFiles = fs.readdirSync(htmlDirectory).filter((filename) ->
    return /\.html$/.test(filename)
  )
  htmlFiles.map((filename) ->
    fs.unlinkSync(path.join(htmlDirectory, filename))
    return
  )
  try
    fs.unlinkSync(htmlTableFile)
  catch err
    if not (err.errno == 34 and err.code == 'ENOENT')
      throw err
  finally
    console.log('clean done.')
  return

build = ->
  products = config.items.map(cacheItemToProduct)
  makeRequestCallback = ->
    urlToHtmlTable = {}

    afterCallbacksDone = ->
      console.log('build done.')
      fs.writeFileSync(htmlTableFile, JSON.stringify(urlToHtmlTable))
      return

    callback = (err, res, body, url) ->
      if not err and res.statusCode == 200
        md5sum = crypto.createHash(hashAlgorithm)
        fileName = md5sum.update(url).digest(digestEncoding) + '.html'
        filePath = path.join(htmlDirectory, fileName)
        encoding = site.getSiteEncoding(site.urlToSite(url))
        fs.writeFileSync(filePath, iconv.decode(new Buffer(body), encoding))
        urlToHtmlTable[url] = filePath
      else if err
        console.error('build html cache caught error')
        console.error('msg: %s', err.message)
        throw err
      else
        console.error('response caught error')
        console.error('url: %s', res.url)
        console.error('status code: %s', res.statusCode)
      return

    counter = products.length
    return (err, res, body, url) ->
      callback(err, res, body, url)
      counter = counter - 1
      if counter == 0
        afterCallbacksDone()
      return
  requestCallback = makeRequestCallback()

  requestWrapper = (url, callback) ->
    request.get(
      {url: url, encoding: null},
      (err, res, body) -> callback(err, res, body, url)
    )

  products.map((item) -> item.url).map((url) ->
    requestWrapper(url, requestCallback)
    return
  )
  return

cleanAndBuild = ->
  clean()
  build()
  return

help = ->
  console.log('Help:')
  console.log('')
  console.log('> node builder.js build')
  console.log('clean and build new cached pages from product.json')
  console.log('')
  console.log('> node builder.js clean')
  console.log('clean already cached page files')
  console.log('')
  console.log('> node builder.js help')
  console.log('print this help message')
  return

main = ->
  argv = process.argv.slice(2)
  if argv.length == 1
    switch argv[0]
      when 'build' then cleanAndBuild()
      when 'clean' then clean()
      when 'help' then help()
      else
        console.error('error: unknown command')
        help()
  else
    console.error('error: unknown commands')
    help()
  return

exports.generateVerdicts = ->
  return config.items.map(cacheItemToVerdict)
module.exports = exports
if require.main == module
  main()
