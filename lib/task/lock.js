var crypto                = require('crypto');
var LockError             = require('../lock/exception.js');
var DEFAULT_TIME_TO_LIVE  = 30000; // 30 seconds

function timestamp() {
  return new Date().getTime();
}

function hashKey(requestorId, taskId) {
  var sha   = crypto.createHash('sha512');
  sha.update(requestorId);
  sha.update(taskId);

  return sha.digest('hex');
}


function isTaskLocked(task) {
  if(task.lock) {
    if(!task.lock.ttl) {
      throw new TypeError('TimeToLiveNotPresent');
    }
    return ( (timestamp() - task.lock.time) < task.lock.ttl );
  }
  return false;
}

function acquire(timeToLive, requestorId, task) {
  timeToLive      = timeToLive || DEFAULT_TIME_TO_LIVE;

  if(!requestorId) {
    throw new TypeError('RequestorIdNotPresent');
  }
  if(!task) {
    throw new TypeError('TaskNotFound');
  }
  if(isTaskLocked(task)) {
    throw new LockError('TaskAlreadyLocked');
  }

  task.lock = {
    key       : hashKey(requestorId, task.id),
    time      : timestamp(),
    ttl       : timeToLive
  };
  return task;
}

function release(requestorId, task) {
  if(!requestorId) {
    throw new TypeError('RequestorIdNotPresent');
  }
  if(!task) {
    throw new TypeError('TaskNotPresent');
  }

  var lock      = task.lock

  // Task isn't locked to it's already released.
  if(!lock) {
    return task;
  }

  var key       = hashKey(requestorId, task.id);

  if (lock.key !== key) {
    throw new LockError('KeyInvalid');
  }

  task.lock = null;

  return task;
}

module.exports  = {
  acquire       : acquire,
  release       : release,
  isTaskLocked  : isTaskLocked,
  timestamp     : timestamp
};
