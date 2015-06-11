
QueueFactory   = require '../../lib/queue.js'
MemoryStore    = require '../../lib/store/memory.js'

describe 'Queue Factory', ->

  it 'should return an instance of a queue', ->
    queue = QueueFactory('test')
    expect(queue.createTask).to.be.a 'function'
    expect(queue.updateTask).to.be.a 'function'

  it 'should not create more than one queue with the same name.', ->
    queue1 = QueueFactory('test')
    queue2 = QueueFactory('test')
    queue3 = QueueFactory('test2')

    expect(queue1).to.eql queue2
    expect(queue3).to.not.eql queue1
    expect(queue3).to.not.eql queue2


  it 'should use a user provided store', ->
    store   =
      createTask: -> null

    queue = QueueFactory('test_store', store)

    expect(queue.store).to.eql store

  it 'should set it\'s name to the given string', ->
    queue = QueueFactory('test')
    expect(queue.name).to.eql 'test'

  describe '::createTask', ->

    it 'should save the given task into the store', ->
      store =
        createTask: sinon.spy()

      queue = QueueFactory('test_create', store)

      task  = "something"

      queue.createTask(task)

      expect(store.createTask.calledOnce).to.be.true
      expect(store.createTask.calledWithExactly("something")).to.be.true

  describe '::updateTask', ->

    it 'should update the given task within the store.', ->
      store =
        updateTask: sinon.spy()

      queue = QueueFactory('test_update', store)

      task  = "something"

      queue.updateTask(task)

      expect(store.updateTask.calledOnce).to.be.true
      expect(store.updateTask.calledWithExactly("something")).to.be.true
