crypto            = require 'crypto'

TaskLock          = require '../../../lib/task/lock.js'
LockError         = require '../../../lib/lock/exception.js'
START_TIME        = 1433985408000

describe 'Task Lock Functions', ->

  describe '::timestamp', ->

    before -> @clock = sinon.useFakeTimers(START_TIME)

    after -> @clock.restore()

    it 'should return the current time as a millisecond precision timestamp', ->
      actual  = TaskLock.timestamp()
      expect(actual).to.eql START_TIME

  describe '::isTaskLocked', ->

    before -> @clock = sinon.useFakeTimers(START_TIME)

    after -> @clock.restore()

    it 'should return false for a task object without a lock.', ->
      task  = {}
      isLocked  = TaskLock.isTaskLocked(task)

      expect(isLocked).to.be.false

    it 'should return true if the lock hasn\'t expired', ->
      task  = { id  : 'my-task-id' }
      task  = TaskLock.acquire(null, 'my-test-id', task)

      expect(TaskLock.isTaskLocked(task)).to.be.true

    it 'should return true if the lock is expired.', ->
      task  = TaskLock.acquire(null, 'my-request-id', { id  : 'my-task-id' })
      @clock.tick(30001)

      expect(TaskLock.isTaskLocked(task)).to.be.false

    it 'should throw a TypeError if a lock does not have a TTL', ->
      task  = TaskLock.acquire(null, 'my-request-id', { id  : 'my-task-id' })
      task.lock.ttl = null

      test  = -> TaskLock.isTaskLocked(task)

      expect(test).to.throw TypeError, /TimeToLiveNotPresent/

  describe '::acquire', ->
    before -> @clock = sinon.useFakeTimers(START_TIME)

    after -> @clock.restore()

    it 'should throw a TypeError if a requestor ID is not given', ->
      test  = -> TaskLock.acquire(null)
      expect(test).to.throw TypeError, /RequestorIdNotPresent/

    it 'should throw a TypeError if a task object is not given', ->
      test  = -> TaskLock.acquire(null, 'my-request-id')

      expect(test).to.throw TypeError, /TaskNotFound/

    it 'should throw a LockError if the given task is already locked', ->
      task  = TaskLock.acquire(null, 'my-request-id' , { id : 'my-task-id' })
      test  = -> TaskLock.acquire(null, 'my-request-id', task)

      expect(test).to.throw LockError, /TaskAlreadyLocked/

    it 'should return a lock with the default ttl if on is not specified', ->
      actual  = TaskLock.acquire(null, 'my-request-id', { id : 'my-task-id' })

      expect(actual.lock.ttl).to.eql 30000

    it 'should return a lock with the current timestamp', ->
      actual  = TaskLock.acquire(null, 'my-request-id', { id : 'my-task-id' })

      expect(actual.lock.time).to.eql START_TIME

    it 'should return a lock with the specified TTL', ->
      actual  = TaskLock.acquire(15000, 'my-request-id', { id : 'my-task-id' })

      expect(actual.lock.ttl).to.eql 15000

    it 'should generate a key from the requestor ID and task ID.', ->
      requestorId   = 'my-request-id'
      taskId        = 'my-task-id'

      hash          = crypto.createHash 'sha512'
      hash.update requestorId
      hash.update taskId

      expected_key  = hash.digest 'hex'

      actual  = TaskLock.acquire(15000, 'my-request-id', { id : 'my-task-id' })

      expect(actual.lock.key).to.eql expected_key

  describe '::release', ->

    before -> @clock  = sinon.useFakeTimers(START_TIME)

    after -> @clock.restore()

    it 'should throw a type error on a missing requestor ID.', ->
      test   = -> TaskLock.release()
      expect(test).to.throw TypeError, /RequestorIdNotPresent/

    it 'should throw a type error on a missing task object', ->
      test  = -> TaskLock.release('my-requestor-id')
      expect(test).to.throw TypeError, /TaskNotPresent/

    it 'should throw a lock error on an invalid requestor ID', ->
      task    = { id  : 'my-task-id' }
      locked  = TaskLock.acquire(null, 'my-requestor-id', task)

      test    = -> TaskLock.release('bad-requestor-id', task)
      expect(test).to.throw LockError, /KeyInvalid/

    it 'should return an unlocked task givent the correct requestor.', ->
      task    = { id : 'my-task-id' }
      locked  = TaskLock.acquire(null, 'my-requestor-id', task)

      unlocked  = TaskLock.release('my-requestor-id', locked)
      expect(unlocked).to.eql task

    it 'should return the task when given an unlocked task', ->
      task    = { id : 'my-task-id' }

      actual  = TaskLock.release('my-requestor-id', task)
      expect(actual).to.eql task
