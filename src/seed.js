// Generated by CoffeeScript 1.8.0
var availableDepartments, getSiteByUrl, htmlSuffix, httpPrefix, loadBenefitVerdict, loadDiscountVerdict, loadPriceVerdict, loadVerdict, siteTable;

httpPrefix = "http://";

htmlSuffix = ".html";

siteTable = {
  amazonCN: {
    url: "www.amazon.cn",
    generateProductUrl: function(productId) {
      return httpPrefix + this.url + "/dp/" + productId;
    }
  },
  amazonUS: {
    url: "www.amazon.com",
    generateProductUrl: function(productId) {
      return httpPrefix + this.url + "/dp/" + productId;
    }
  },
  amazonJP: {
    url: "www.amazon.co.jp",
    generateProductUrl: function(productId) {
      return httpPrefix + this.url + "/dp/" + productId;
    }
  },
  jingdong: {
    url: "www.jd.com",
    generateProductUrl: function(productId) {
      return httpPrefix + this.url.replace("www", "item") + "/" + productId + htmlSuffix;
    }
  }
};

getSiteByUrl = function(url) {
  var self, _;
  return ((function() {
    var _results;
    _results = [];
    for (_ in siteTable) {
      self = siteTable[_];
      if (self.url === url) {
        _results.push(self);
      }
    }
    return _results;
  })()).pop();
};

loadPriceVerdict = function(price, seed) {
  if (price.compare === "under") {
    seed.verdictPrice = function(x) {
      return x < price.target;
    };
  } else if (price.compare === "above") {
    seed.verdictPrice = function(x) {
      return price.target < x;
    };
  } else if (price.compare === "equal") {
    seed.verdictPrice = function(x) {
      return x === price.target;
    };
  } else {
    console.log("unknown price verdict word %s", price.compare);
    process.exit();
  }
};

loadDiscountVerdict = function(discount, seed) {
  if (discount.compare === "under") {
    seed.verdictDiscount = function(x) {
      return x < discount.target;
    };
  } else if (discount.compare === "above") {
    seed.verdictDiscount = function(x) {
      return discount.target < x;
    };
  } else if (discount.compare === "equal") {
    seed.verdictDiscount = function(x) {
      return x === discount.target;
    };
  } else {
    console.log("unknown discount verdict %s", discount.compare);
    process.exit();
  }
};

loadBenefitVerdict = function(benefit, seed) {
  var regex;
  regex = new Regex(benefit.regex, benefit.option);
  seed.verdictBenefits = function(benefits) {
    return benefits.some(function(elt, idx, arr) {
      return regex.test(elt);
    });
  };
};

loadVerdict = function(item, seed) {
  if (item.price) {
    loadPriceVerdict(item.price, seed);
  }
  if (item.discount) {
    loadDiscountVerdict(item.discount, seed);
  }
  if (item.benefit) {
    loadBenefitVerdict(item.benefit, seed);
  }
  return function(result) {
    result = false;
    if (reulst || this.verdictPrice) {
      result = result || this.verdictPrice(result.price);
    }
    if (result || this.verdictDiscount) {
      result = result || this.verdictDiscount(result.discount);
    }
    if (result || this.verdictBenefits) {
      result = result || this.verdictBenefits(result.benefits);
    }
    return result;
  };
};

module.exports = function(item) {
  var seed, targetSite;
  seed = {
    id: item.id,
    site: item.site
  };
  targetSite = getSiteByUrl(item.site);
  seed.url = targetSite.generateProductUrl(item.id);
  seed.verdict = loadVerdict(item, seed);
  return seed;
};

availableDepartments = {
  digitalMusic: "Digital Music",
  book: "Book",
  movie: "Movie",
  music: "Music",
  game: "Game",
  home: "Home",
  sport: "Sport",
  outdoor: "Outdoor",
  credit: "Credit"
};
