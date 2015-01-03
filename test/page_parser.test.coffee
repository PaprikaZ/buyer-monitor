rewire = require('rewire')
pageParser = rewire('../lib/page_parser.js')

describe('page parser', ->
  describe('site selector', ->
    it('should select amazon cn parser when given www.amazon.cn')
    it('should select amazon us parser when given www.amazon.com')
    it('should select amazon jp parser when given www.amazon.co.jp')
    it('should select jingdong parser when given www.jd.com')
    it('should throw error when neither above site given')
    return
  )

  describe('parse', ->
    it('should deliver result with all mandatory fields')
    return
  )

  describe('amazon cn', ->
    it('should parse all predefined cached pages as expected')
    return
  )

  describe('amazon com', ->
    it('should parse all predefined cached pages as expected')
    return
  )

  describe('amazon jp', ->
    it('should parse all predefined cached pages as expected')
    return
  )

  describe('jingdong', ->
    it('should parse all predefined cached pages as expected')
    return
  )

  return
)
