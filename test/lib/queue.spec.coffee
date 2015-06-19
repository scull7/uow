
Queue             = require '../../lib/queue.js'
TaskRequest       = require '../../lib/task/request.js'
MemoryStore       = require '../../lib/store/memory.js'
TaskLock          = require '../../lib/task/lock.js'
{ inherits }      = require 'util'
{ EventEmitter }  = require 'events'

describe 'Queue', ->
  queue = null
  store = null

  beforeEach ->

    store     = new MemoryStore()
    queue     = new Queue(store)

  it 'should follow the optional new pattern', ->
    queue     = Queue(store)

    expect(queue instanceof Queue).to.be.true

  describe '::taskComplete', ->
    completeTask        = null
    caughtCompleteEvent = false

    beforeEach (done) ->

      queue.on 'task::finished', ->
        caughtCompleteEvent = true

      queue.taskAdd({ name: 'complete-task' })

      .then (task) -> queue.taskComplete('complete-worker', task.id, 'complete')

      .then (task) ->
        completeTask = task
        done()

    it 'should call the store to update the task', ->
      expect(completeTask.status).to.eql 'success'
      expect(completeTask.response[0]).to.eql 'complete'

    it 'should emit a task::update event', ->
      expect(caughtCompleteEvent).to.be.true

    it 'should change the response to an array if it\'s not currently an array',
    ->
      queue.taskAdd({ name  : 'test-not-array' })

      .then (task) ->
        task.response = 'not-an-array'
        queue.store.updateTask('worker-id', task)

      .then (task) -> queue.taskComplete('worker-id', task.id, 'done')

      .then (task) ->
        expect(task.response).to.eql [
          'not-an-array'
          'done'
        ]

  describe '::taskFail', ->
    failedTask        = null
    caughtFailedEvent = false

    beforeEach (done) ->

      queue.on 'task::failed', (task) ->
        caughtFailedEvent = true

      queue.taskAdd({ name: 'fail-task' })

      .then (task) -> queue.taskFail('fail-worker', task.id, 'fail-response')

      .then (task) ->
        failedTask = task
        done()

    it 'should call the store to mark the task as failed', ->
      expect(failedTask.status).to.eql 'failed'
      expect(failedTask.response[0]).to.eql 'fail-response'

    it 'should emit a task::fail event', ->
      expect(caughtFailedEvent).to.be.true

  describe '::taskCancel', ->
    cancelledTask     = null
    caughtCancelEvent = false

    beforeEach (done) ->

      queue.on 'task::cancelled', (task) ->
        caughtCancelEvent = true

      queue.taskAdd({ name: 'cancel-test' })

      .then (task) -> queue.taskCancel('cancel-worker', task.id, 'response')

      .then (task) ->
        cancelledTask = task
        done()

    it 'should call the store to mark the task as cancelled', ->

      expect(cancelledTask.status).to.eql 'cancelled'
      expect(cancelledTask.response[0]).to.eql 'response'

    it 'should emit a task::cancel event', ->
      expect(caughtCancelEvent).to.be.true

  describe '::taskGetById', ->

    it 'should call the store to get a task by its identifier', ->
      queue.taskAdd({ name: 'get-by-id-task' })

      .then (task) -> queue.taskGetById(task.id)

      .then (task) ->
        expect(task.name).to.eql 'get-by-id-task'

  describe '::taskAdd', ->

    it 'should call the store to persist the given task object.', ->

      queue.taskAdd({ name: 'test-add-task' })

      .then (task) ->
        expect(task.id).to.not.be.undefined
        return queue.taskGetById(task.id)

      .then (task) ->
        expect(task.name).to.eql 'test-add-task'

    it 'should throw an TypeError given a task with an ID', ->

      queue.taskAdd({
        id    : 'my-task-id'
        name  : 'test-add-task'
      })

      .then -> throw new Error('UnexpectedSuccess')

      .catch TypeError, (e) ->
        expect(e.message).to.eql 'InvalidTaskObject'

  describe '::taskLock', ->
    result      = null
    workerId    = 'lock-worker'
    task        = { name: 'lock-task' }
    caughtEvent = false

    before (done) ->

      queue.on 'task::locked', (task) ->
        caughtEvent = true
        done()

      queue.taskAdd(task)

      .then (task) -> queue.taskLock(workerId, task.id)

      .then (task) -> result = task

    it 'should call the store to lock the task', ->
      expect(result.id).to.not.be.undefined
      expect(result.id).to.be.a 'string'
      expect(result.semaphore.key).to.be.a 'string'

    it 'should emit a task::lock event', ->
      expect(caughtEvent).to.be.true

  describe '::taskUnlock', ->
    result      = null
    workerId    = 'lock-worker'
    task        = { name: 'lock-task' }
    caughtEvent = false

    before (done) ->

      queue.on 'task::unlocked', (task) ->
        caughtEvent = true
        done()

      queue.taskAdd(task)

      .then (task) -> queue.taskLock(workerId, task.id)

      .then (task) -> queue.taskUnlock(workerId, task.id)

      .then (task) -> result = task

    it 'should call the store to unlock the task', ->
      expect(result.semaphore).to.be.null
      expect(result.id).to.be.a 'string'

    it 'should emit a task::unlock event', ->
      expect(caughtEvent).to.be.true

  describe '::taskYield', ->
    result      = null
    workerId    = 'yield-worker'
    task        = { name  : 'yield-task' }
    yieldEvent  = false
    clock       = null
    startTime   = 1434734400000
    tenMinutes  = 10 * 60 * 1000

    before (done) ->
      clock        = sinon.useFakeTimers(startTime)

      queue.on 'task::finished', ->
        yieldEvent  = true

      task      = new TaskRequest('yield-task', queue)
      task.later('every 10 minutes')

      task.send()

      .tap -> clock.tick tenMinutes

      .then (task) -> queue.taskYield(workerId, task.id, 'something')

      .then (task) -> result = task

      .then -> done()

    after -> clock.restore()

    it 'should throw a TypeError if the task doesn\'t have a schedule', ->

      no_schedule_task  = { name : 'no-schedule-for-me' }

      queue.taskAdd(task)

      .then (task) -> queue.taskYield('my-worker-id', task.id, 'blah')

      .then -> throw new Error('UnexpectedSuccess')

      .catch TypeError, (e) ->
        expect(e.message).to.eql 'TaskNotScheduled'

    it 'should emit a task finished event', ->
      expect(yieldEvent).to.be.true

    it 'should not update the task status', ->
      expect(result.status).to.eql 'new'

    it 'should update the after time', ->
      expect(result.after).to.eql (new Date().getTime()) + tenMinutes

  describe '::taskProgress', ->
    result      = null
    workerId    = 'progress-worker'
    task        = { name: 'progress-task' }
    caughtEvent = false

    before (done) ->

      queue.on 'task::progress', (task) ->
        caughtEvent = true
        done()

      queue.taskAdd(task)

      .then (task) -> queue.taskProgress(workerId, task.id, 'some-progress')

      .then (task) -> result  = task

    it 'should lock the task before updating', ->
      expect(result.semaphore).to.not.be.undefined

    it 'should call the store to update the task progress', ->
      expect(result.progress).to.eql 'some-progress'

    it 'should emit a task::progress event', ->
      expect(caughtEvent).to.be.true

  describe '::workerRegister', ->

    it 'should add the given worker to the registry', ->
      worker  =
        taskReady : sinon.spy()

      id      = queue.workerRegister(['test1', 'test2'], worker)

      expect(queue.registry[id].worker).to.eql worker
      expect(queue.registry[id].types).to.eql [ 'test1', 'test2' ]

    it 'should bind the worker to the task::ready event', (done) ->
      worker  =
        taskReady : (type, id) ->
          expect(type).to.eql 'test-register'
          expect(id).to.eql 'register-task-id'
          done()

      task    = {
        id      : 'register-task-id'
        name    : 'test-register'
        pickle  : -> null
      }

      id      = queue.workerRegister([ 'test-register' ], worker)

      queue.workerNotify(task)

    it 'should not call the worker if the task name is not in the type list',
    (done) ->
      worker  =
        taskReady : sinon.spy()

      notType = {
        id      : 'not-type-task'
        name    : 'not-in-list'
        pickle  : -> null
      }

      queue.workerRegister([ 'test1', 'test2' ], worker)

      queue.workerNotify(notType)

      setTimeout ->
        expect(worker.taskReady.called).to.be.false
        done()
      , 5

  describe '::workerNotify', ->

    it 'should throw a TypeError if the task is not persisted', ->
      not_persisted = {
        name    : 'not-persisted'
        pickle  : -> null
      }

      test  = -> queue.workerNotify(not_persisted)
      expect(test).to.throw TypeError, /TaskNotPersisted/

    it 'should throw a TypeError if the task name is missing', ->
      persisted = {
        id      : 'i-am-persisted'
        pickle  : -> null
      }

      test  = -> queue.workerNotify(persisted)
      expect(test).to.throw TypeError, /TaskTypeMissing/

    it 'should emit a task ready event', (done) ->
      test_task = {
        id      : 'worker-notify-id'
        name    : 'worker-notify-task'
        pickle  : -> null
      }

      queue.on 'task::ready', (taskName, taskId) ->
        expect(taskId).to.eql 'worker-notify-id'
        expect(taskName).to.eql 'worker-notify-task'
        done()

      queue.workerNotify(test_task)

    it 'should be called when the store emits a ready event.', (done) ->

      task  = {
        id    : 'ready-task-id'
        name  : 'test1'
        pickle: -> null
      }

      queue.on 'task::ready', (taskName, taskId) ->
        expect(taskName).to.eql 'test1'
        expect(taskId).to.eql 'ready-task-id'
        done()

      store.emit 'ready', task

  describe '::workerStatus', ->

    it 'should throw an Error', ->

      test = -> queue.workerStatus()
      expect(test).to.throw Error, /NotImplemented/
