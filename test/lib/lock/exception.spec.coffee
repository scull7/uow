
LockError          = require '../../../lib/lock/exception.js'

describe 'Task Lock Exception', ->

  it 'should accept a message in its constructor', ->
    expected  = 'This is the expected message.'
    exception = new LockError(expected)
    expect(exception.message).to.eql expected

  it 'should extend the standard error.', ->
    exception   = new LockError()
    expect(exception).to.be.an.instanceOf Error

  it 'should return a Lock Error instance', ->
    exception   = new LockError()
    expect(exception).to.be.an.instanceOf LockError
