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
      test  = -> store.createTask { id : "bad-things-here" }
      expect(test).to.throw TypeError
      expect(test).to.throw "InvalidTaskObject"

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
