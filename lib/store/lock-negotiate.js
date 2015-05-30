var
  LockError             = require("./lock-exception.js"),

  DEFAULT_TIME_TO_LIVE  = 30000,// 30 seconds.

  timestamp             = function () {
                          return new Date().getTime();
                        }
;

function negotiate (time_to_live, task) {
  if(!task) {
    throw new TypeError("TaskNotFound");
  }
  if(!time_to_live) {
    time_to_live    = DEFAULT_TIME_TO_LIVE;
  }
  var lock_ttl      = task.lock.ttl || time_to_live,
      lock_time     = task.lock.time || 0;

  if (lock_time && lock_ttl > (timestamp() - lock_time) ) {
    throw new LockError();
  }

  task.lock         = {
    time            : timestamp(),
    ttl             : time_to_live
  };

  return task;
}

module.exports      = negotiate;
