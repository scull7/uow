var later                 = require("later");
var Queue                 = require("./queue");

var DEFAULT_MAX_ATTEMPTS  = 1;
var DEFAULT_TASK_STATUS   = "new";
var DEFAULT_TASK_PRIORITY = 0;
var DEFAULT_BACKOFF_ALGO  = "fixed";

var STATUS_NEW            = "new";
var STATUS_READY          = "ready";
var STATUS_FAILED         = "failed";
var STATUS_SUCCESS        = "success";
var STATUS_CANCELLED      = "success";

var PRIORITY_MAP          = {
    low:        -10,
    normal:     0,
    medium:     -5,
    high:       -10,
    critical:   -15
};

var BACKOFF_ALGOS         = {
    fixed: function (task) {
      return task.delay + timestamp();
    }
};

function timestamp() {
  return new Date().getTime();
}

function getPriority(name) {
  return PRIORITY_MAP[name] || 0;
}

function Task(name, queue) {
  this.queue           = queue;
  this.task            = {
    id                : null,
    name              : name,
    status            : DEFAULT_TASK_STATUS,
    data              : {},
    after             : timestamp(),
    delay             : 0,
    priority          : DEFAULT_TASK_PRIORITY,
    attempts          : {
      failed          : 0,
      cancelled       : 0,
      timed_out       : 0,
      total           : 0,
      max             : DEFAULT_MAX_ATTEMPTS,
    },
    backoff           : DEFAULT_BACKOFF_ALGO,
    schedule          : null
  };

}

Task.prototype        = {
  later: function (expression) {

    var schedule      = later.parse.text(expression);
    var next          = later.schedule(schedule).next(1);

    this.task.after        = next.getTime();

    return this;
  },

  delay: function (milliseconds) {

    var delay         = parseInt(milliseconds, 10);

    if (isNaN(delay)) {
      throw new TypeError("InvalidDelay");
    }

    this.task.delay   = delay;

    return this;
  },

  attempts: function (count) {
    var max           = parseInt(count, 10);

    if (isNaN(max)) {
      throw new TypeError("InvalidMaxAttempts");
    }

    this.task.attempts.max = max;

    return this;
  },

  priority: function (priority) {
    var level         = PRIORITY_MAP[priority] || parseInt(priority, 10);

    if(isNaN(level)) {
      throw new TypeError("InvalidPriority");
    }
    this.task.priority  = level;

    return this;
  },

  backoff: function (algo) {
    throw new Error("NotImplemented");
  },

  save: function () {
    var method        = this.task.id ? "updateTask" : "createTask";
    return this.queue[method](this.task);
  }
};

function TaskFactory(queue_name, task_name) {
  var queue           = Queue(queue_name);
  var task            = TaskFactory(task_name, queue);

  return task;
}

Task.STATUS           = {
  NEW                 : STATUS_NEW,
  READY               : STATUS_READY,
  FAILED              : STATUS_FAILED,
  SUCCESS             : STATUS_SUCCESS,
  CANCELLED           : STATUS_CANCELLED
};
Task.PRIORITY         = {
  LOW                 : PRIORITY_MAP.low,
  NORMAL              : PRIORITY_MAP.normal,
  MEDIUM              : PRIORITY_MAP.medium,
  HIGH                : PRIORITY_MAP.high,
  CRITICAL            : PRIORITY_MAP.critical
};

module.exports        = TaskFactory;
