bluebird        = require 'bluebird'
Worker          = require '../../lib/worker.js'
Queue           = require '../../lib/queue.js'
TaskRequest     = require '../../lib/task/request.js'
MemoryStore     = require '../../lib/store/memory.js'

describe 'Worker', ->
  queue   = null
  store   = null
  options = null
  worker  = null

  beforeEach ->
    store   = new MemoryStore()
    queue   = new Queue(store)
    sinon.spy queue, 'workerRegister'

    options =
      types : [ 'foo', 'type2' ]

    worker  = new Worker(queue, options)
    sinon.spy(worker, 'taskReady')

  it 'should register with the queue on construction', ->

    expect(worker.id).to.be.a 'string'
    expect(queue.workerRegister.calledOnce).to.be.true

    calledWith  = queue.workerRegister.calledWithExactly(
      options.types,
      worker
    )
    expect(calledWith).to.be.true

  it 'should initialize the listeners hash', ->
    expect(worker.listeners).to.be.an 'object'
    expect(worker.listeners).to.be.empty

  describe '::taskReady', ->
    fooHandler    = null
    fooTask       = null
    booHandler    = null
    barTask       = null
    lockedHandler = null
    lockedTask    = null

    beforeEach (done) ->

      fooHandler  = sinon.spy()
      worker.on 'foo', fooHandler

      booHandler  = sinon.spy()
      worker.on 'boo', booHandler

      fooRequest = new TaskRequest('foo', queue)
      fooRequest.data {
        foo : 'bar'
        baz : 'buzz'
      }

      barRequest  = new TaskRequest('bar', queue)
      barRequest.data {
        bar   : 'foo'
        buzz  : 'baz'
      }

      lockedRequest = new TaskRequest('foo', queue)
      lockedRequest.data {
        blah  : 'is-locked'
      }

      promise       = lockedRequest.send()
                    .then (task) -> queue.taskLock('bad-id', task.id)

      bluebird.join fooRequest.send(), barRequest.send(), promise

      .spread (foo, bar, locked) ->
        fooTask     = foo
        barTask     = bar
        lockedTask  = locked

        store.emit 'ready', barTask
        store.emit 'ready', fooTask
        store.emit 'ready', lockedTask

        setTimeout done, 1

    it 'should call the foo handler with the foo task', ->
      expect(fooHandler.calledOnce).to.be.true
      expect(fooHandler.calledWithExactly(worker.id, fooTask)).to.be.true

    it 'should not call taskReady for the unregistered boo type', ->
      expect(booHandler.called).to.be.false

  describe '::hasListenerFor', ->

    it 'should return false when a listener does not exist for an event', ->
      actual  = worker.hasListenerFor('not::there')
      expect(actual).to.be.false

    it 'should return true when a listener is set for a given event name.', ->
      worker.on 'exists', -> null
      actual  = worker.hasListenerFor('exists')
      expect(actual).to.be.true

  describe '::emit', ->

    it 'should call the listener with the given arguments', ->
      handler = sinon.spy()
      worker.on 'foo', handler

      worker.emit 'foo', 'bar', 'baz', 'buzz'

      expect(handler.calledOnce).to.be.true

      calledWith  = handler.calledWithExactly('bar','baz','buzz')
      expect(calledWith).to.be.true

    it 'should not call listeners for events that are not listened for.', ->
      handler = sinon.spy()
      worker.on 'bar', handler

      worker.emit 'foo', 'bar', 'baz', 'buzz'

      expect(handler.called).to.be.false

  describe '::on', ->

    it 'should throw a type exception when a handler is not a function.', ->
      test  = -> worker.on 'not-function', { fn: -> 'boo' }
      expect(test).to.throw TypeError, /InvalidHandler/

    it 'should add a listener to the listeners hash', ->
      handler = -> 'foo'
      worker.on 'foo', handler

      expect(worker.hasListenerFor('foo')).to.be.true
      expect(worker.listeners.foo).to.eql handler

    it 'should throw an Error if you try to register more than one handler ' +
    'for an event', ->
      foo = -> 'foo'
      bar = -> 'bar'
      worker.on 'foo', foo
      test  = -> worker.on 'foo', bar

      expect(test).to.throw Error, /DuplicateListener/

    it 'should return a the worker instance', ->
      res = worker.on 'foo', -> 'bar'
      expect(res).to.eql worker
