rewire = require('rewire')
monitor = rewire('../lib/monitor.js')

describe('monitor module', ->
  describe('create monitor', ->
    it('should throw access token empty error when no token found')
    it('should throw verdicts empty error when no verdicts found')
    return
  )

  describe('verify user tokens', ->
    it('should call callback when all verifications done')
    it('should throw error when all tokens are invalid')
    it('should drop invalid tokens when all verifications done')
    it('should mark token invalid when request caught error')
    it('should mark token invalid when response code nok')
    return
  )

  describe('monitoring', ->
    it('should make sure push queue is empty when send requests')
    it('should bypass database pop error')
    it('should do nothing when all seeds is delayed')
    it('should push back delayed seeds when timeout')
    return
  )
  return
)
