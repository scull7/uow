
later       = require('later')
Task        = require '../../lib/task.js'
LockError   = require '../../lib/lock/exception.js'

START_TIME  = -875735838000

describe 'Task Factory', ->
  queue     = null
  task      = null
  workerId  = 'my-test-worker'

  beforeEach ->
    @clock    = sinon.useFakeTimers(START_TIME)

    queue     =
      taskLock      : sinon.spy()
      taskComplete  : sinon.spy()
      taskFail      : sinon.spy()
      taskCancel    : sinon.spy()
      taskYield     : sinon.spy()
      taskProgress  : sinon.spy()

    task      = new Task('test-task', queue)

  afterEach -> @clock.restore()

  it 'should return a Task object', ->

    expect(task.queue).to.eql queue
    expect(task.id).to.be.null
    expect(task.name).to.eql 'test-task'
    expect(task.status).to.eql Task.STATUS.NEW
    expect(task.data).to.eql {}
    expect(task.after).to.eql START_TIME
    expect(task.delay).to.eql 0
    expect(task.priority).to.eql Task.PRIORITY.NORMAL
    expect(task.attempts).to.eql {
      failed    : 0
      cancelled : 0
      timed_out : 0
      total     : 0
      max       : 1
    }
    expect(task.backoff).to.eql 'fixed'
    expect(task.schedule).to.be.null

  describe '::lock', ->
    it 'should throw a LockError if the task is not persisted.', ->
      test  = -> task.lock(workerId)
      expect(test).to.throw LockError, 'TaskNotPersisted'

    it 'should call the queue to lock this task for a worker.', ->
      task.id = 'this-is-my-id'
      task.lock(workerId)

      expect(queue.taskLock.calledOnce).to.be.true

      calledWith  = queue.taskLock.calledWithExactly(workerId, 'this-is-my-id')
      expect(calledWith).to.be.true

  describe '::complete', ->
    it 'should throw a TypeError if the task is not persisted.', ->
      test  = -> task.complete(workerId)
      expect(test).to.throw TypeError, 'TaskNotPersisted'

    it 'should call the queue to mark the task as complete', ->
      task.id   = 'this-is-my-id'
      response  = 'response'
      task.complete(workerId, response)

      expect(queue.taskComplete.calledOnce).to.be.true

      calledWith  = queue.taskComplete.calledWithExactly(
        workerId,
        'this-is-my-id',
        'response'
      )
      expect(calledWith).to.be.true

  describe '::fail', ->
    it 'should throw a TypeError if the task is not persisted.', ->
      test  = -> task.fail(workerId)
      expect(test).to.throw TypeError, 'TaskNotPersisted'

    it 'should call the queue to mark this task as failed', ->
      task.id   = 'this-is-my-id'
      response  = 'response'
      task.fail(workerId, response)

      expect(queue.taskFail.calledOnce).to.be.true

      calledWith  = queue.taskFail.calledWithExactly(
        workerId,
        'this-is-my-id',
        'response'
      )
      expect(calledWith).to.be.true

  describe '::yield', ->

    it 'should throw a TypeError if the task is not persisted.', ->
      test  = -> task.yield(workerId)
      expect(test).to.throw TypeError, 'TaskNotPersisted'

    it 'should call the queue to mark the task as finished ' +
    'and schedule the next run', ->
      task.id   = 'yield-task-id'
      response  = 'my-response'

      task.yield(workerId, response)

      expect(queue.taskYield.calledOnce).to.be.true

      calledWith  = queue.taskYield.calledWithExactly(
        workerId,
        'yield-task-id',
        'my-response'
      )
      expect(calledWith).to.be.true

  describe '::cancel', ->
    it 'should throw a TypeError if the task is not persisted.', ->
      test  = -> task.cancel(workerId)
      expect(test).to.throw TypeError, 'TaskNotPersisted'

    it 'should call the queue to mark the task as cancelled.', ->
      task.id   = 'this-is-my-id'
      response  = 'response'
      task.cancel(workerId, response)

      expect(queue.taskCancel.calledOnce).to.be.true

      calledWith  = queue.taskCancel.calledWithExactly(
        workerId,
        'this-is-my-id',
        'response'
      )
      expect(calledWith).to.be.true

  describe '::progress', ->
    it 'should throw a TypeError if the task is not persisted.', ->
      test  = -> task.progress(workerId)
      expect(test).to.throw TypeError, 'TaskNotPersisted'

    it 'should call the queue to update the task processing progress.', ->
      task.id   = 'this-is-my-id'
      response  = 'response'
      task.progress(workerId, response)

      expect(queue.taskProgress.calledOnce).to.be.true

      calledWith  = queue.taskProgress.calledWithExactly(
        workerId,
        'this-is-my-id',
        'response'
      )
      expect(calledWith).to.be.true
