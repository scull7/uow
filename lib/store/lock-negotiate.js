var LockError               = require("./lock-exception.js")

const DEFAULT_TIME_TO_LIVE  = 30000; // 30 seconds.
const timestamp             = function () {
  return new Date().getTime();
}

function negotiate (time_to_live, task) {
  if(!task) {
    throw new TypeError("TaskNotFound");
  }
  if(!time_to_live) {
    time_to_live    = DEFAULT_TIME_TO_LIVE;
  }
  lock_ttl          = task.lock.ttl || time_to_live;
  lock_time         = task.lock.time || 0;

  if (lock_time && lock_ttl > (timestam() - lock_time) ) {
    throw new LockError();
  }

  task.lock         = {
    time            : timstamp(),
    ttl             : time_to_live
  };

  return task;
}

module.exports      = negotiate;
