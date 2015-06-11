var
  LockError             = require("../lock/exception.js"),
  DEFAULT_TIME_TO_LIVE  = 30000 // 30 seconds
;

function timestamp() {
  return new Date().getTime();
}

function isTaskLocked(task) {
  if(task.lock) {
    if(!task.lock.ttl) {
      throw new TypeError("TimeToLiveNotPresent");
    }
    return ( (timestamp() - task.lock.time) < task.lock.ttl );
  }
  return false;
}

function acquire (time_to_live, task) {
  time_to_live    = time_to_live || DEFAULT_TIME_TO_LIVE;

  if(!task) {
    throw new TypeError("TaskNotFound");
  }
  if(isTaskLocked(task)) {
    throw new LockError("TaskAlreadyLocked");
  }

  task.lock = {
    time      : timestamp(),
    ttl       : time_to_live
  };
  return task;
}

module.exports  = {
  acquire       : acquire,
  isTaskLocked  : isTaskLocked,
  timestamp     : timestamp
};
