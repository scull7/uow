
uow         = require '../../lib/uow.js'
Queue       = require '../../lib/queue.js'
TaskRequest = require '../../lib/task/request.js'
TaskWorker  = require '../../lib/worker.js'
{ MemoryStore } = require 'uow-store'

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
      store     = MemoryStore()
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

  describe 'Task Process', ->
    request   = null
    worker    = null
    result    = null
    response  = null
    store     = null

    before (done) ->
      store   = new MemoryStore()
      queue   = uow('process-test', { store : store })

      request = uow('process-test').requestTask('process')
      request.data {
        foo   : 'bar'
      }

      worker  = uow('process-test').registerWorker({ types: 'process' })
      worker.on 'process', (workerId, task) ->
        response  = {
          workerId  : workerId
          taskId    : task.id
        }

        task.complete(workerId, response)

        .then -> done()

      request.send()

      .then (task) ->

        task.status = 'ready'
        return store.updateTask(worker.id, task)

      .then (task) ->
        result  = task
        store.emit 'ready', task

    it 'should mark the task as successfully run', ->

      store.getTaskById(result.id)

      .then (task) ->
        expect(result.status).to.eql 'success'
