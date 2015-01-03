// Generated by CoffeeScript 1.8.0
var rewire, seed;

rewire = require('rewire');

seed = rewire('../lib/seed.js');

describe('seed', function() {
  var Seed, discountCompare, knownSite, mockErrorMsg, notAnNumber, priceCompare, reviewCompare, testDiscount, testID, testPrice, testReview, unknownSite;
  testID = 'test0000';
  knownSite = 'www.amazon.cn';
  unknownSite = 'www.example.com';
  testPrice = 9;
  priceCompare = 'under';
  testDiscount = 10;
  discountCompare = 'above';
  reviewCompare = 'above';
  testReview = 8;
  notAnNumber = 'null';
  seed.__set__({
    logger: {
      debug: function() {},
      info: function() {},
      error: function() {}
    }
  });
  mockErrorMsg = 'mock msg';
  Seed = seed.__get__('Seed');
  describe('constructor', function() {
    var called, makeCalledTrue;
    called = false;
    makeCalledTrue = function() {
      called = true;
    };
    beforeEach(function() {
      called = false;
    });
    it('should route to site not support handler when site not in support list', function() {
      var product, revert;
      product = {
        id: testID,
        site: unknownSite,
        price: {
          compare: priceCompare,
          target: testPrice
        }
      };
      revert = seed.__set__({
        siteNotSupportHandler: function() {
          makeCalledTrue();
          throw new Error(mockErrorMsg);
        }
      });
      (function() {
        return new Seed(product);
      }).should["throw"](mockErrorMsg);
      called.should.be["true"];
      revert();
    });
    it('should route to illegal type handler when detect not a number', function() {
      var product, revert;
      product = {
        id: testID,
        site: knownSite,
        discount: {
          compare: discountCompare,
          target: notAnNumber
        }
      };
      revert = seed.__set__({
        illegalTypeHandler: function() {
          makeCalledTrue();
          throw new Error(mockErrorMsg);
        }
      });
      (function() {
        return new Seed(product);
      }).should["throw"](mockErrorMsg);
      called.should.be["true"];
      revert();
    });
    it('should initialize its id and site attributes by copy from product', function() {
      var product, s;
      product = {
        id: testID,
        site: knownSite,
        discount: {
          compare: discountCompare,
          target: testDiscount
        }
      };
      s = new Seed(product);
      s.id.should.be.equal(testID);
      s.site.should.be.equal(knownSite);
    });
    it('should initialize its url attribute which have http prefix', function() {
      var product, s;
      product = {
        id: testID,
        site: knownSite,
        discount: {
          compare: discountCompare,
          target: testDiscount
        }
      };
      s = new Seed(product);
      s.should.have.property('url');
      s.url.should.be.a.String;
      s.url.should.startWith('http://');
    });
    it('should initialize at least one sub verdict entry', function() {
      var product, s, verdictMethods;
      product = {
        id: testID,
        site: knownSite,
        discount: {
          compare: discountCompare,
          target: testDiscount
        }
      };
      s = new Seed(product);
      verdictMethods = seed.__get__('_MANDATORY_VERDICT_METHODS');
      verdictMethods.reduce((function(partial, name) {
        return partial || (typeof s[name] === 'function');
      }), false).should.be["true"];
    });
    it('should initialize verdict entry', function() {
      var product, s;
      product = {
        id: testID,
        site: knownSite,
        price: {
          compare: priceCompare,
          target: testPrice
        }
      };
      s = new Seed(product);
      s.verdict.should.be.a.Function;
    });
  });
  describe('verdict', function() {
    it('should give price under target or not', function() {
      var highPriceResult, lowPriceResult, product, s, samePriceResult;
      product = {
        id: testID,
        site: knownSite,
        price: {
          comapre: priceCompare,
          target: testPrice
        }
      };
      lowPriceResult = {
        price: testPrice - 1
      };
      samePriceResult = {
        price: testPrice
      };
      highPriceResult = {
        price: testPrice + 1
      };
      s = new Seed(product);
      s.verdict(lowPriceResult).should.be["true"];
      s.verdict(samePriceResult).should.be["false"];
      s.verdict(highPriceResult).should.be["false"];
    });
    it('should give discount above target or not', function() {
      var highDiscountResult, lowDiscountResult, product, s, sameDiscountResult;
      product = {
        id: testID,
        site: knownSite,
        discount: {
          compare: discountCompare,
          target: testDiscount
        }
      };
      lowDiscountResult = {
        discount: testDiscount - 1
      };
      sameDiscountResult = {
        discount: testDiscount
      };
      highDiscountResult = {
        discount: testDiscount + 1
      };
      s = new Seed(product);
      s.verdict(lowDiscountResult).should.be["false"];
      s.verdict(sameDiscountResult).should.be["false"];
      s.verdict(highDiscountResult).should.be["true"];
    });
    it('should give review above target or not', function() {
      var highReviewResult, lowReviewResult, product, s, sameReviewResult;
      product = {
        id: testID,
        site: knownSite,
        review: {
          compare: reviewCompare,
          target: testReview
        }
      };
      lowReviewResult = {
        review: testReview - 1
      };
      sameReviewResult = {
        review: testReview
      };
      highReviewResult = {
        review: testReview + 1
      };
      s = new Seed(product);
      s.verdict(lowReviewResult).should.be["false"];
      s.verdict(sameReviewResult).should.be["false"];
      s.verdict(highReviewResult).should.be["true"];
    });
    it('should give instore state is acceptable or not', function() {
      var product, s;
      product = {
        id: testID,
        site: knownSite,
        instore: true
      };
      s = new Seed(product);
      s.verdict({
        instore: true
      }).should.be["true"];
      s.verdict({
        instore: false
      }).should.be["false"];
    });
    it('should give any benefits matched or not', function() {
      var matchedResult, notMatchedResult, product, s;
      product = {
        id: testID,
        site: knownSite,
        benefits: {
          regex: '20% off',
          option: 'i'
        }
      };
      matchedResult = {
        benefits: ['get total 200 with instant 50 off', '20% OFF']
      };
      notMatchedResult = {
        benefits: ['buy two with one free', 'get total 200 with instant 50 off']
      };
      s = new Seed(product);
      s.verdict(matchedResult).should.be["true"];
      s.verdict(notMatchedResult).should.be["false"];
    });
    it('should summarize all sub verdicts with and logic', function() {
      var matchedResult, notMatchedResult, product, s;
      product = {
        id: testID,
        site: knownSite,
        price: {
          compare: priceCompare,
          target: testPrice
        },
        discount: {
          compare: discountCompare,
          target: testDiscount
        },
        review: {
          compare: reviewCompare,
          target: testReview
        },
        instore: true,
        benefits: {
          regex: '20% off',
          option: 'i'
        }
      };
      matchedResult = {
        price: testPrice - 1,
        discount: testDiscount + 1,
        review: testReview + 1,
        instore: true,
        benefits: ['get total 200 with instant 50 off', '20% OFF']
      };
      notMatchedResult = {
        price: testPrice - 1,
        discount: testDiscount + 1,
        review: testReview + 1,
        instore: false,
        benefits: ['get total 200 with instant 50 off', 'two with one free']
      };
      s = new Seed(product);
      s.verdict(matchedResult).should.be["true"];
      s.verdict(notMatchedResult).should.be["false"];
    });
  });
  describe('verdict missing handler', function() {
    var verdictMissingHandler;
    verdictMissingHandler = seed.__get__('verdictMissingHandler');
    it('should throw verdict missing error', function() {
      verdictMissingHandler.bind(null, testID, knownSite).should["throw"]('product missing verdict field error');
    });
  });
  describe('site not support handler', function() {
    var siteNotSupportHandler;
    siteNotSupportHandler = seed.__get__('siteNotSupportHandler');
    it('should throw site not support error', function() {
      siteNotSupportHandler.bind(null, unknownSite).should["throw"]('product site not support error');
    });
  });
  describe('illegal type handler', function() {
    var illegalTypeHandler;
    illegalTypeHandler = seed.__get__('illegalTypeHandler');
    it('should throw illegal verdict value error', function() {
      illegalTypeHandler.bind(null, 'price', 'number').should["throw"]('product illegal verdict value error');
    });
  });
  describe('none verdict loaded handler', function() {
    var noneVerdictLoadedHandler;
    noneVerdictLoadedHandler = seed.__get__('noneVerdictLoadedHandler');
    it('should throw none verdict loaded handler', function() {
      noneVerdictLoadedHandler.bind(null, testID, knownSite).should["throw"]('none verdict loaded');
    });
  });
});