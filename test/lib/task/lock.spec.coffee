
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
      task  = {}
      task  = TaskLock.acquire(null, task)

      expect(TaskLock.isTaskLocked(task)).to.be.true

    it 'should return true ifj the lock is expired.', ->
      task  = TaskLock.acquire(null, {})
      @clock.tick(30001)

      expect(TaskLock.isTaskLocked(task)).to.be.false

    it 'should throw a TypeError if a lock does not have a TTL', ->
      task  = TaskLock.acquire(null, {})
      task.lock.ttl = null

      test  = -> TaskLock.isTaskLocked(task)

      expect(test).to.throw TypeError, /TimeToLiveNotPresent/

  describe '::acquire', ->
    before -> @clock = sinon.useFakeTimers(START_TIME)

    after -> @clock.restore()

    it 'should throw a TypeError if a task object is not given', ->
      test  = -> TaskLock.acquire()

      expect(test).to.throw TypeError, /TaskNotFound/

    it 'should throw a LockError if the given task is already locked', ->
      task  = TaskLock.acquire(null, {})
      test  = -> TaskLock.acquire(null, task)

      expect(test).to.throw LockError, /TaskAlreadyLocked/

    it 'should return a lock with the default ttl if on is not specified', ->
      actual  = TaskLock.acquire(null, {})

      expect(actual.lock.ttl).to.eql 30000

    it 'should return a lock with the current timestamp', ->
      actual  = TaskLock.acquire(null, {})

      expect(actual.lock.time).to.eql START_TIME

    it 'should return a lock with the specified TTL', ->
      actual  = TaskLock.acquire(15000, {})

      expect(actual.lock.ttl).to.eql 15000
