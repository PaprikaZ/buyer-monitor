fs = require("fs")
path = require("path")
minimist = require("minimist")

printHelp = ->
  console.log("Usage:")
  console.log("  node app.js")
  console.log("    add id <product-id> site <www.example.com>")
  console.log("    remove id <product-id>")
  console.log("    reset")
  console.log("    help")
  console.log("")
  console.log("The most commonly used example:")
  console.log("")
  console.log("  List all existing products")
  console.log("  > node app.js list")
  console.log("  Also you can specify the id or site as to filter result")
  console.log("  > node app.js list site www.amazon.cn")
  console.log("  > node app.js list id B00JG8GOWU ")
  console.log("")
  console.log("  Add product id B00JG8GOWU on site www.amazon.com")
  console.log("  > node app.js add B00JG8GOWU www.amazon.com")
  console.log("")
  console.log("  Remove product id B00JG8GOWU")
  console.log("  > node app.js remove B00JG8GOWU site www.amazon.com")
  console.log("  Since duplicated is merely happen, you ignore site option")
  console.log("  > node app.js remove B00JG8GOWU")
  console.log("")
  console.log("  Reset all added products")
  console.log("  > node app.js reset")
  console.log("")
  console.log("  See this help page")
  console.log("  > node app.js help")
  console.log("")
  console.log("The monitor products located in product.json at root path.")
  return

productFile = path.join(__dirname, "../product.json")
listProduct = (id, site) ->
  JSON.parse(fs.readFileSync(productFile)).forEach((elt, index, err) ->
    console.log("product id %s, site %s", elt.id, elt.site)
    return
  )
  console.log("done.")
  return

addProduct = (id, site) ->
  products = JSON.parse(fs.readFileSync(productFile))
  duplicatedProducts = products.filter((elt, index, err) ->
    return elt.id == id and elt.site == site
  )
  
  if duplicatedProducts.length == 0
    products.push({id: id, site: site})
    fs.writeFileSync(productFile, JSON.stringify(products))
    console.log("done.", id, site)
  else
    console.log("product id %s, site %s already existed", id, site)
  return

removeProduct = (id, site) ->
  products = fs.readFileSync(productFile)
  fs.writeFileSync(
    productFile,
    JSON.stringify(products.filter((elt, index, err) ->
      if site
        return elt.id != id or elt.site != site
      else
        return elt.id != id
      )
    )
  )
  console.log("done.")
  return

resetUserData = ->
  process.stdout.write("Are you sure to reset product data? [yes/no] ")
  process.stdin.setEncoding("utf8")
  process.stdin.once("data", (input) ->
    input = input.trim().toLowerCase()
    if input == "y" or input == "yes"
      fs.writeFileSync(productFile, JSON.stringify([]))
    else if input == "n" or input == "no"
      console.log("Reset aborted by user")
    else
      console.log("Invalid response, quit")
    process.exit()
    return
  )
  return

argvStyleConvert = (argv) ->
  return argv.map((elt, index, err) ->
    if elt == "add"
      return "--add"
    else if elt == "remove"
      return "--remove"
    else if elt == "list"
      return "--list"
    else if elt == "id"
      return "--id"
    else if elt == "site"
      return "--site"
    else if elt == "reset"
      return "--reset"
    else if elt == "help"
      return "--help"
    else
      return elt
  )
minimistOpt = {}
parser = module.exports
parser.parse = (argv, launch) ->
  argv = argvStyleConvert(argv)
  argv = minimist(argv, minimistOpt)
  operations =[argv.add, argv.remove, argv.list]
  validOpertions = operations.filter((elt, idx, err) ->
    return elt == true
  )
  if 1 < validOpertions
    console.log("Please do add or remove operation, not both.")
  else if argv.list
    listProduct()
  else if argv.add and argv.site and argv.id
    addProduct(argv.id, argv.site)
  else if argv.remove and argv.id
    removeProduct(arg.id, arg.site)
  else if argv.reset
    resetUserData()
  else if argv.help
    printHelp()
  else if argv._.length == 0
    launch()
  else
    console.log("Unknown arguments, please see help with 'node app.js help'")
  return
