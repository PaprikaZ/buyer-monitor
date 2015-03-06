rewire = require('rewire')

describe('model module', ->
  model = rewire('../lib/model.js')

  describe('enum types corresponding to site', ->
    site = rewire('../lib/site.js')

    it('should cover all presented sites from site module', ->
      sitesFromModule = site.__get__('sites').map((elt) -> elt.site)
      enumSites = model.__get__('availableSites')
      sitesFromModule.forEach((s) -> enumSites.should.containEql(s))
      return
    )
    
    it('should cover all presented currencies from site module', ->
      currenciesFromModule = site.__get__('sites').map((elt) -> elt.currency)
      enumCurrencies = model.__get__('availableCurrencies')
      currenciesFromModule.forEach((c) -> enumCurrencies.should.containEql(c))
      return
    )
    return
  )

  describe('enum types corresponding to seed', ->
    seed = rewire('../lib/seed.js')

    it('should cover all presented verdict fields from seed module', ->
      fieldsFromModule = seed.AVAILABLE_VERDICT_FIELDS
      enumFields = model.__get__('availableVerdictFields')
      fieldsFromModule.forEach((f) -> enumFields.should.containEql(f))
      return
    )

    it('should cover all presented verdict methods from seed module', ->
      methodsFromModule = seed.AVAILABLE_METHODS
      enumMethods = model.__get__('availableVerdictMethods')
      methodsFromModule.forEach((m) -> enumMethods.should.containEql(m))
      return
    )
    return
  )
  return
)
