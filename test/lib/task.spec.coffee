
later       = require('later')
TaskFactory = require '../../lib/task.js'

START_TIME  = -875735838000

describe 'Task Factory', ->
  task      = null

  beforeEach -> task  = TaskFactory('test_queue', 'test_task')

  it 'should return a Task object', ->
    expect(task.delay).to.be.a 'function'
    expect(task.attempts).to.be.a 'function'
    expect(task.priority).to.be.a 'function'
    expect(task.backoff).to.be.a 'function'
    expect(task.save).to.be.a 'function'

  describe '::later', ->
    before -> @clock = sinon.useFakeTimers(START_TIME)

    after -> @clock.restore()

    it 'should accept a later.js expression and set the task after property', ->
      expression  = 'at 10:00pm tonight'
      expected    = -875671200000

      task.later(expression)

      expect(task.task.after).to.eql expected

  describe '::delay', ->

    it 'should set the task delay to the given number of milliseconds.', ->
      expected  = 10000

      task.delay(expected)

      expect(task.task.delay).to.eql expected

    it 'should throw a TypeError if the delay is not a number', ->
      test  = -> task.delay('not a number')

      expect(test).to.throw TypeError, /InvalidDelay/

  describe '::attempts', ->

    it 'should set the max attempts', ->
      expected  = 10

      task.attempts(expected)

      expect(task.task.attempts.max).to.eql expected

    it 'should throw a TypeError if the max attempts is not a number.', ->
      test = -> task.attempts('not a number')

      expect(test).to.throw TypeError, /InvalidMaxAttempts/

  describe '::priority', ->

    it 'should set the priority that\'s in the map', ->
      expected  = TaskFactory.PRIORITY.LOW

      task.priority(expected)

      expect(task.task.priority).to.eql expected

    it 'should set the priority to a given integer', ->
      expected  = 2

      task.priority(expected)

      expect(task.task.priority).to.eql expected

    it 'should throw a TypeError if the priority code is not a number.', ->
      test = -> task.priority('not a number')

      expect(test).to.throw TypeError, /InvalidPriority/

  describe '::backoff', ->

    it 'should set the backoff algorithm', ->

      task.backoff('fixed')

      expect(task.task.backoff).to.eql 'fixed'

    it 'should throw a TypeError if the algorithm is unknown.', ->

      test = -> task.backoff('bad algo')
      
      expect(test).to.throw TypeError, /InvalidBackoffAlgorithm/

  describe '::save', ->

    it 'should call the createTask if the current task doesn\'t have an ID.', ->

      spy = task.queue.createTask = sinon.spy()

      task.save()

      expect(spy.calledOnce).to.be.true
      expect(spy.calledWithExactly(task.task)).to.be.true

    it 'should call the updateTask if the current task has an ID.', ->

      spy = task.queue.updateTask = sinon.spy()

      task.task.id = 1234
      task.save()

      expect(spy.calledOnce).to.be.true
      expect(spy.calledWithExactly(task.task)).to.be.true
