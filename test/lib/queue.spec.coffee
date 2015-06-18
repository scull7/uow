
Queue         = require '../../lib/queue.js'
MemoryStore   = require '../../lib/store/memory.js'

describe 'Queue', ->
  queue     = null
  mockStore = null

  beforeEach ->
    mockStore =
      on          : sinon.spy()
      createTask  : sinon.spy()
      updateTask  : sinon.spy()
      getTaskById : sinon.spy()
      lockTask    : sinon.spy()
      unlockTask  : sinon.spy()

    queue     = new Queue(mockStore)

  describe '::taskUpdate', ->

    it.skip 'should call the store to update the task', ->

    it.skip 'should emit a task::update event', ->

  describe '::taskFail', ->

    it.skip 'should call the store to mark the task as failed', ->

    it.skip 'should emit a task::fail event', ->

  describe '::taskCancel', ->

    it.skip 'should call the store to mark the task as cancelled', ->

    it.skip 'should emit a task::cancel event', ->

  describe '::taskGetById', ->

    it.skip 'should call the store to get a task by its identifier', ->

  describe '::taskAdd', ->

    it.skip 'should call the store to persist the given task object.', ->

    it.skip 'should throw an error given a task with an ID', ->

  describe '::taskAccessAllowed', ->

    it.skip 'should throw a LockError if thw worker ID is not correct', ->

    it.skip 'should not throw a LockError for an expired lock', ->

    it.skip 'should not throw a LockError for an unlocked task', ->

    it.skip 'should not throw a LockError for a correct worker ID', ->

  describe '::taskLock', ->

    it.skip 'should call the store to lock the task', ->

    it.skip 'should store the lock', ->

    it.skip 'should emit a task::lock event', ->

  describe '::taskUnlock', ->

    it.skip 'should call the store to unlock the task', ->

    it.skip 'should remove the task lock from its lock registry', ->
      
    it.skip 'should emit a task::unlock event', ->

  describe '::taskProgress', ->

    it.skip 'should call the store to update the task progress', ->

    it.skip 'should emit a task::progress event', ->

  describe '::workerRegister', ->

    it.skip 'should add the given worker to the registry', ->

    it.skip 'should bind the worker to the task::ready event', ->

  describe '::workerNotify', ->

    it 'should emit a task ready event', (done) ->
      test_task = { name: 'worker-notify-task' }

      queue.on 'task::ready', (task) ->
        expect(task.name).to.eql 'worker-notify-task'
        done()

      queue.workerNotify(test_task)

    it.skip 'should be called when the store emits a ready event.', ->

  describe '::workerStatus', ->

    it 'should throw an Error', ->

      test = -> queue.workerStatus()
      expect(test).to.throw Error, /NotImplemented/
