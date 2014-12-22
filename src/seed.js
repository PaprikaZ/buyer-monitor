// Generated by CoffeeScript 1.8.0
var availableDepartments, getSiteByUrl, htmlSuffix, httpPrefix, siteTable;

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

module.exports = function(id, siteUrl) {
  var targetSite;
  targetSite = getSiteByUrl(siteUrl);
  return {
    id: id,
    site: siteUrl,
    url: targetSite.generateProductUrl(id)
  };
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
