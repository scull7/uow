crypto                = require 'crypto'
MemoryStore           = require "../../../lib/store/memory.js"
LockError             = require '../../../lib/lock/exception.js'

describe "Memory Store", ->
  store     = null
  before -> store = new MemoryStore()

  describe "::createTask", ->

    it "should be a function with an arity of one", ->
      expect(store.createTask).to.be.a "function"
      expect(store.createTask.length).to.eql 1

    it "should set a UUID on the given object.", ->
      store.createTask {}
      .then (task) ->
        expect(task.id.length).to.eql 36

    it "should throw a TypeError if a task object with a UUID is given.", ->
      store.createTask { id : "bad-things-here" }
      .then (task) -> throw new Error("Should not get here.")
      .catch (e) ->
        expect(e.name).to.eql "TypeError"
        expect(e.message).to.eql "InvalidTaskObject"

  describe "::updateTask", ->

    it "should be a function with an arity of two", ->
      expect(store.updateTask).to.be.a "function"
      expect(store.updateTask.length).to.eql 2

    it 'should throw a lock error if the task is locked by another worker.', ->
      store.createTask {}
      .then (task) -> store.lockTask('worker-1', task.id)

      .then (task) ->
        task.updated  = 1
        store.updateTask('worker-2', task)

      .then -> throw Error('UnexpectedSuccess')

      .catch LockError, (e) ->
        expect(e.message).to.eql 'TaskLocked'

    it 'should update a locked task for the lock holding worker.', ->
      store.createTask {}

      .then (task) -> store.lockTask('worker-1', task.id)

      .then (task) ->
        task.updated = 2
        store.updateTask('worker-1', task)

      .then (task) ->
        expect(task.updated).to.eql 2

    it "should update the stored object", ->
      store.createTask {}
      .then (task) ->
        task.updated    = 1
        return task
      .then (task) -> store.updateTask('worker-1', task)
      .then (task) ->
        expect(task.updated).to.eql 1
        return store.getTaskById(task.id)
      .then (task) ->
        expect(task.updated).to.eql 1

    it "should throw a TypeError if a task object without a UUID is given.", ->
      store.updateTask 'worker-id', { updated: 1 }
      .then -> throw new Error("Should not get here.")
      .catch (e) ->
        expect(e.name).to.eql "TypeError"
        expect(e.message).to.eql "InvalidTaskObject"

  describe "::getTaskById", ->

    it "should be a function with an arity of one", ->
      expect(store.getTaskById).to.be.a "function"
      expect(store.getTaskById.length).to.eql 1

    it "should return null if the requested task is not found.", ->
      store.getTaskById("does not exist")
      .then (task) ->
        expect(task).to.be.null

    it "should throw a TypeError if an ID is not given.", ->
      store.getTaskById()
      .then -> throw new Error("Should not get here.")
      .catch (e) ->
        expect(e.name).to.eql "TypeError"
        expect(e.message).to.eql "TaskIdNotProvided"

  describe "::lockTask", ->
    now      = 1433029250000
    beforeEach ->
      @clock = sinon.useFakeTimers(now)


    afterEach ->
      @clock.restore()

    it "should be a function with an arity of three", ->
      expect(store.lockTask).to.be.a "function"
      expect(store.lockTask.length).to.eql 3

    it "should throw a TypeError if a worker ID is not given.", ->
      store.lockTask()
      .then -> throw new Error("Should not get here.")
      .catch (e) ->
        expect(e.name).to.eql "TypeError"
        expect(e.message).to.eql "WorkerIdNotProvided"

    it "should throw a TypeError if a task ID is not given.", ->
      store.lockTask('my-worker-id')
      .then -> throw new Error("Should not get here.")
      .catch (e) ->
        expect(e.name).to.eql "TypeError"
        expect(e.message).to.eql "TaskIdNotProvided"

    it "should lock an unlocked task", ->
      task          = { name : "test-task" }
      requestor     = 'my-requestor-id'
      expected_key  = null

      store.createTask(task)
      .then (task) ->
        hash  = crypto.createHash 'sha512'
        hash.update(requestor)
        hash.update(task.id)

        expected_key  = hash.digest 'hex'

        store.lockTask(requestor, task.id)

      .then (task) ->
        expect(task.semaphore).to.be.an "object"
        expect(task.semaphore.time).to.eql now
        expect(task.semaphore.key).to.eql expected_key
        # 30 seconds is the default TTL
        expect(task.semaphore.ttl).to.eql 30000

  describe '::unlockTask', ->
    now      = 1433029250000
    beforeEach ->
      @clock = sinon.useFakeTimers(now)


    afterEach ->
      @clock.restore()

    it 'should be a function with an arity of two', ->
      expect(store.unlockTask).to.be.a 'function'
      expect(store.unlockTask.length).to.eql 2

    it "should throw a TypeError if a worker ID is not given.", ->
      store.unlockTask()
      .then -> throw new Error("Should not get here.")
      .catch (e) ->
        expect(e.name).to.eql "TypeError"
        expect(e.message).to.eql "WorkerIdNotProvided"

    it "should throw a TypeError if a task ID is not given.", ->
      store.unlockTask('my-worker-id')
      .then -> throw new Error("Should not get here.")
      .catch (e) ->
        expect(e.name).to.eql "TypeError"
        expect(e.message).to.eql "TaskIdNotProvided"

    it 'should throw a LockError if an invalid requestor is given.', ->
      task          = { name  : 'test-task' }
      requestor     = 'unlock-requestor'

      store.createTask(task)

      .then (task) -> store.lockTask(requestor, task.id)

      .then (task) -> store.unlockTask('bad-requestor', task.id)

      .then -> throw new Error('UnexpectedSuccess')

      .catch (e) ->
        expect(e.name).to.eql 'LockError'
        expect(e.message).to.eql 'KeyInvalid'


    it 'should unlock a locked task given the correct requestor ID', ->
      task          = { name  : 'test-task' }
      requestor     = 'unlock-requestor'

      store.createTask(task)

      .then (task) -> store.lockTask(requestor, task.id)

      .then (task) -> store.unlockTask(requestor, task.id)

      .then (task) ->

        expect(task.semaphore).to.eql null
        expect(task.name).to.eql 'test-task'
