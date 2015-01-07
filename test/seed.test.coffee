rewire = require('rewire')

describe('seed module', ->
  seed = rewire('../lib/seed.js')
  seed.__set__({
    logger:
      debug: ->
      info: ->
      error: ->
  })

  testID = 'test0000'
  knownSite = 'www.amazon.cn'
  unknownSite = 'www.example.com'
  testPrice = 9
  priceCompare = 'under'
  testDiscount = 10
  discountCompare = 'above'
  reviewCompare = 'above'
  testReview = 8
  notAnNumber = 'null'
  mockErrorMsg = 'mock msg'
  Seed = seed.__get__('Seed')

  describe('constructor', ->
    called = false
    makeCalledTrue = ->
      called = true
      return
    makeCalledFalse = ->
      called = false
      return
    restore = null
    beforeEach(->
      makeCalledFalse()
      restore = seed.__set__({
        siteNotSupportHandler: ->
        illegalTypeHandler: ->
        verdictMissingHandler: ->
        noneVerdictLoadedHandler: ->
      })
      return
    )
    afterEach(-> restore())

    it('should initialize its id and site fields copy from product', ->
      product =
        id: testID
        site: knownSite
        discount:
          compare: discountCompare
          target: testDiscount
      s = new Seed(product)
      s.id.should.be.equal(testID)
      s.site.should.be.equal(knownSite)
      return
    )

    it('should initialize its url field', ->
      product =
        id: testID
        site: knownSite
        discount:
          compare: discountCompare
          target: testDiscount
      s = new Seed(product)
      s.should.have.property('url')
      s.url.should.be.a.String
      return
    )

    it('should initialize at least one verdict method', ->
      product =
        id: testID
        site: knownSite
        discount:
          compare: discountCompare
          target: testDiscount
      s = new Seed(product)
      verdictMethods = seed.__get__('_AVAILABLE_VERDICT_METHODS')
      verdictMethods.some((method) ->
        return (typeof(s[method]) == 'function')
      ).should.be.true
      return
    )

    it('should route to site not support handler when site not in support list', ->
      product =
        id: testID
        site: unknownSite
        price:
          compare: priceCompare
          target: testPrice
      seed.__set__({
        siteNotSupportHandler: makeCalledTrue
      })
      s = new Seed(product)
      called.should.be.true
      return
    )

    it('should route to illegal type handler when detect not a number', ->
      product =
        id: testID
        site: knownSite
        discount:
          compare: discountCompare
          target: notAnNumber
      seed.__set__({
        illegalTypeHandler: makeCalledTrue
      })
      s = new Seed(product)
      called.should.be.true
      return
    )
    return
  )

  describe('verdict', ->
    it('should give price under target or not', ->
      product =
        id: testID
        site: knownSite
        price:
          comapre: priceCompare
          target: testPrice
      lowPriceResult =
        price: testPrice - 1
      samePriceResult =
        price: testPrice
      highPriceResult =
        price: testPrice + 1
      s = new Seed(product)
      s.verdict(lowPriceResult).should.be.true
      s.verdict(samePriceResult).should.be.false
      s.verdict(highPriceResult).should.be.false
      return
    )

    it('should give discount above target or not', ->
      product =
        id: testID
        site: knownSite
        discount:
          compare: discountCompare
          target: testDiscount
      lowDiscountResult =
        discount: testDiscount - 1
      sameDiscountResult =
        discount: testDiscount
      highDiscountResult =
        discount: testDiscount + 1
      s = new Seed(product)
      s.verdict(lowDiscountResult).should.be.false
      s.verdict(sameDiscountResult).should.be.false
      s.verdict(highDiscountResult).should.be.true
      return
    )

    it('should give review above target or not', ->
      product =
        id: testID
        site: knownSite
        review:
          compare: reviewCompare
          target: testReview
      lowReviewResult =
        review: testReview - 1
      sameReviewResult =
        review: testReview
      highReviewResult =
        review: testReview + 1
      s = new Seed(product)
      s.verdict(lowReviewResult).should.be.false
      s.verdict(sameReviewResult).should.be.false
      s.verdict(highReviewResult).should.be.true
      return
    )

    it('should give instore state is acceptable or not', ->
      product =
        id: testID
        site: knownSite
        instore: true
      s = new Seed(product)
      s.verdict({instore: true}).should.be.true
      s.verdict({instore: false}).should.be.false
      return
    )

    it('should give any benefits matched or not', ->
      product =
        id: testID
        site: knownSite
        benefits:
          regex: '20% off'
          option: 'i'
      matchedResult =
        benefits: [
          'get total 200 with instant 50 off',
          '20% OFF'
        ]
      notMatchedResult =
        benefits: [
          'buy two with one free',
          'get total 200 with instant 50 off'
        ]
      s = new Seed(product)
      s.verdict(matchedResult).should.be.true
      s.verdict(notMatchedResult).should.be.false
      return
    )

    it('should summarize all sub verdicts with and logic', ->
      product =
        id: testID
        site: knownSite
        price:
          compare: priceCompare
          target: testPrice
        discount:
          compare: discountCompare
          target: testDiscount
        review:
          compare: reviewCompare
          target: testReview
        instore: true
        benefits:
          regex: '20% off'
          option: 'i'
      matchedResult =
        price: testPrice - 1
        discount: testDiscount + 1
        review: testReview + 1
        instore: true
        benefits: [
          'get total 200 with instant 50 off',
          '20% OFF'
        ]
      notMatchedResult =
        price: testPrice - 1
        discount: testDiscount + 1
        review: testReview + 1
        instore: false
        benefits: [
          'get total 200 with instant 50 off',
          'two with one free'
        ]
      s = new Seed(product)
      s.verdict(matchedResult).should.be.true
      s.verdict(notMatchedResult).should.be.false
      return
    )
    return
  )

  describe('equal', ->
    it('should return true if both id and site equal', ->
      productA =
        id: testID
        site: 'www.amazon.cn'
        review:
          compare: reviewCompare
          target: testReview
      productB =
        id: 'foo'
        site: 'www.amazon.cn'
        review:
          compare: reviewCompare
          target: testReview
      productC =
        id: testID
        site: 'www.amazon.com'
        review:
          compare: reviewCompare
          target: testReview

      sa = new Seed(productA)
      sb = new Seed(productB)
      sc = new Seed(productC)
      sa.equal(sb).should.be.false
      sa.equal(sc).should.be.false
      sb.equal(sc).should.be.false
      sa.equal(sa).should.be.true
      return
    )
    return
  )

  describe('verdict missing handler', ->
    verdictMissingHandler = seed.__get__('verdictMissingHandler')
    it('should throw error', ->
      verdictMissingHandler.bind(null, testID, knownSite)
        .should.throw('value missing error, non verdict fields specified')
      return
    )
    return
  )

  describe('site not support handler', ->
    siteNotSupportHandler = seed.__get__('siteNotSupportHandler')
    it('should throw error', ->
      siteNotSupportHandler.bind(null, unknownSite)
        .should.throw('value not support error, verdict site')
      return
    )
    return
  )

  describe('illegal type handler', ->
    illegalTypeHandler = seed.__get__('illegalTypeHandler')
    it('should throw error', ->
      illegalTypeHandler.bind(null, testID, knownSite, 'price')
        .should.throw('value not support error, illegal verdict value')
      return
    )
    return
  )

  describe('none verdict loaded handler', ->
    noneVerdictLoadedHandler = seed.__get__('noneVerdictLoadedHandler')
    it('should throw error', ->
      noneVerdictLoadedHandler.bind(null, testID, knownSite)
        .should.throw('load error, none verdict fields loaded')
      return
    )
    return
  )
  return
)
