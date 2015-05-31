MemoryStore           = require "../../../lib/store/memory.js"

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

    it "should be a function with an arity of one", ->
      expect(store.updateTask).to.be.a "function"
      expect(store.updateTask.length).to.eql 1

    it "should update the stored object", ->
      store.createTask {}
      .then (task) ->
        task.updated    = 1
        return task
      .then (task) -> store.updateTask(task)
      .then (task) ->
        expect(task.updated).to.eql 1
        return store.getTaskById(task.id)
      .then (task) ->
        expect(task.updated).to.eql 1

    it "should throw a TypeError if a task object without a UUID is given.", ->
      store.updateTask { updated: 1 }
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

    it "should be a function with an arity of two", ->
      expect(store.lockTask).to.be.a "function"
      expect(store.lockTask.length).to.eql 2

    it "should throw a TypeError if an ID is not given.", ->
      store.lockTask()
      .then -> throw new Error("Should not get here.")
      .catch (e) ->
        expect(e.name).to.eql "TypeError"
        expect(e.message).to.eql "TaskIdNotProvided"

    it "should lock a never before locked task", ->
      task  = { name : "test-task" }
      store.createTask(task)
      .then (task) -> store.lockTask(task.id)
      .then (task) ->
        expect(task.lock).to.be.an "object"
        expect(task.lock.time).to.eql now
        # 30 seconds is the default TTL
        expect(task.lock.ttl).to.eql 30000
