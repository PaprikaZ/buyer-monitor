rewire = require('rewire')
visitor = rewire('../lib/visitor.js')

describe('visitor', ->
  describe('create', ->
    it('should given amazon cn visitor when seed site be www.amazon.cn')
    it('should given amazon us visitor when seed site be www.amazon.com')
    it('should given amazon jp visitor when seed site be www.amazon.co.jp')
    it('should given jingdong visitor when seed site be www.jd.com')
    it('should throw error when seed site not support')
    return
  )

  describe('visit', ->
    it('should transfer control to page handler when everything ok')
    it('should bypass error when request caught error')
    it('should throw error when response is nok')
    return
  )

  describe('page handler', ->
    it('should first create page parser and wait for result ready')
    it('should push parse result to queue')
    it('should then add timestamp to parse result')
    it('should finally push result with timestamp to database for storage')
    it('should route to database fault handler when database is nok')
    return
  )
  return
)
