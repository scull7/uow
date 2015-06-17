
later         = require('later')

TaskRequest   = require '../../../lib/task/request.js'
TaskPriority  = require '../../../lib/task/priority.js'

START_TIME  = -875735838000

describe 'Task Request', ->
  request   = null

  beforeEach -> request  = new TaskRequest('test_queue', 'test_task')

  it 'should return a Task object', ->
    expect(request.delay).to.be.a 'function'
    expect(request.attempts).to.be.a 'function'
    expect(request.priority).to.be.a 'function'
    expect(request.backoff).to.be.a 'function'
    expect(request.send).to.be.a 'function'

  it 'should allow you to specify the task constructor', ->
    constructor_spy = sinon.spy()
    class TestTask
      constructor: constructor_spy

    request = new TaskRequest('test-task', 'my-queue', TestTask)

    expect(constructor_spy.calledOnce).to.be.true
    calledWith  = constructor_spy.calledWithExactly('test-task', 'my-queue')
    expect(calledWith).to.be.true

  describe '::data', ->

    it 'should set the task data key to the given data object.', ->
      expect(request.task.data).to.eql {}

      expected  = { test_key  : 'test_value' }
      actual    = request.data(expected)

      expect(actual.task.data).to.eql expected

  describe '::later', ->
    before -> @clock = sinon.useFakeTimers(START_TIME)

    after -> @clock.restore()

    it 'should accept a later.js expression and set the task after property', ->
      expression  = 'at 10:00pm tonight'
      expected    = -875671200000

      request.later(expression)

      expect(request.task.after).to.eql expected

  describe '::delay', ->

    it 'should set the task delay to the given number of milliseconds.', ->
      expected  = 10000

      request.delay(expected)

      expect(request.task.delay).to.eql expected

    it 'should throw a TypeError if the delay is not a number', ->
      test  = -> request.delay('not a number')

      expect(test).to.throw TypeError, /InvalidDelay/

  describe '::attempts', ->

    it 'should set the max attempts', ->
      expected  = 10

      request.attempts(expected)

      expect(request.task.attempts.max).to.eql expected

    it 'should throw a TypeError if the max attempts is not a number.', ->
      test = -> request.attempts('not a number')

      expect(test).to.throw TypeError, /InvalidMaxAttempts/

  describe '::priority', ->

    it 'should set the priority that\'s in the map', ->
      expected  = TaskPriority.LOW

      request.priority(expected)

      expect(request.task.priority).to.eql expected

    it 'should set the priority to a given integer', ->
      expected  = 2

      request.priority(expected)

      expect(request.task.priority).to.eql expected

    it 'should throw a TypeError if the priority code is not a number.', ->
      test = -> request.priority('not a number')

      expect(test).to.throw TypeError, /InvalidPriority/

  describe '::backoff', ->

    it 'should set the backoff algorithm', ->

      request.backoff('fixed')

      expect(request.task.backoff).to.eql 'fixed'

    it 'should throw a TypeError if the algorithm is unknown.', ->

      test = -> request.backoff('bad algo')

      expect(test).to.throw TypeError, /InvalidBackoffAlgorithm/

  describe '::send', ->
    it 'should call taskAdd on the queue with the current task object', ->
      queue   =
        taskAdd : sinon.spy()

      request = new TaskRequest('test-request', queue)

      request.send()

      expect(queue.taskAdd.calledOnce).to.be.true
      expect(queue.taskAdd.calledWithExactly(request.task)).to.be.true
