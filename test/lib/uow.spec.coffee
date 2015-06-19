
uow         = require '../../lib/uow.js'
Queue       = require '../../lib/queue.js'
MemoryStore = require '../../lib/store/memory.js'
TaskRequest = require '../../lib/task/request.js'
TaskWorker  = require '../../lib/worker.js'

describe 'Unit of Work Queue', ->

  it 'should not create more than one queue with a given name', ->
    sinon.spy(Queue)

    queue1 = uow('test1')
    queue2 = uow('test1')

    expect(queue1.id).to.be.a 'string'
    expect(queue1.id).to.eql queue2.id

  describe '::requestTask', ->
    store = null
    queue = null

    beforeEach ->
      store     = new MemoryStore()
      queue     = uow('request-task-test', { store: store })

    it 'should return a new task request object', ->
      request = uow('request-task-test').requestTask('my-test')
      expect(request).to.be.an.instanceOf TaskRequest

  describe '::registerWorker', ->

    it 'should throw a TypeError if no task types are specified', ->
      test  = -> uow('request-task-test').registerWorker()
      expect(test).to.throw TypeError, /NoTypesSpecified/

      test  = -> uow('request-task-test').registerWorker({})
      expect(test).to.throw TypeError, /NoTypesSpecified/

      test  = -> uow('request-task-test').registerWorker({ types: [] })
      expect(test).to.throw TypeError, /NoTypesSpecified/

    it 'should throw a TypeError if specified types list is not ' +
    'a string or array', ->
      test  = -> uow('request-task-test').registerWorker({ types: 1234 })
      expect(test).to.throw TypeError, /TypesInvalid/

      test  = -> uow('request-task-test').registerWorker({ types: {} })
      expect(test).to.throw TypeError, /TypesInvalid/

    it 'should allow a string type', ->
      worker  = uow('request-task-test').registerWorker({ types: 'test-type' })

      registered  = worker.queue.registry[worker.id]
      expect(registered.types).to.eql [ 'test-type'   ]

    it 'should return a registered task worker', ->
      worker  = uow('request-task-test').registerWorker({
        types : ['test-type']
      })
      expect(worker).to.be.an.instanceOf TaskWorker
      expect(worker.queue).to.be.an.instanceOf Queue

      registered  = worker.queue.registry[worker.id]
      expect(registered.worker).to.eql worker
