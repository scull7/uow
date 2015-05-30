var
  bluebird                  = require("bluebird"),
  later                     = require("later"),
  Queue                     = require("./queue")
;
const timestamp            = function () {
  return new Date().getTime();
},

DEFAULT_MAX_ATTEMPTS  = 1,
      DEFAULT_TASK_STATUS   = "new";
const DEFAULT_TASK_PRIORITY = 0;
const DEFAULT_BACKOFF_ALGO  = "fixed"

const STATUS_NEW            = "new";
const STATUS_READY          = "ready";
const STATUS_FAILED         = "failed";
const STATUS_SUCCESS        = "success";
const STATUS_CANCELLED      = "success";

const PRIORITY_MAP    = {
  "low"               : -10,
  "normal"            : 0,
  "medium"            : -5,
  "high"              : -10,
  "critical"          : -15
};

const BACKOFF_ALGOS   = {
  "fixed"             : task => task.delay + timestamp()
};

const _getPriority    = function (name) {
  return PRIORITY_MAP[name] || 0;
};

function Task(name, queue) {
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

};

Task.prototype        = {
  later               : function (expression) {
    let schedule      = later.parse.text(expression);
    let next          = later.schedule(schedule).next(1);

    this.task.after        = next.getTime();

    return this;
  },

  delay               : function (milliseconds) {
    delay             = parseInt(milliseconds, 10);

    if (isNaN(delay)) {
      throw new TypeError("InvalidDelay");
    }

    this.task.delay        = delay;

    return this;
  },

  attempts            : function (count) {
    max               = parseInt(count, 10);

    if (isNaN(max)) {
      throw new TypeError("InvalidMaxAttempts");
    }

    this.task.attempts.max = max;

    return this;
  },

  priority            : function (priority) {
    level             = PRIORITY_MAP[priority] or parseInt(priority, 10);

    if(isNaN(level)) {
      throw new TypeError("InvalidPriority");
    }
    this.task.priority  = level;

    return this;
  },

  backoff             : function (algo) {
    throw new Error("NotImplemented");
  },

  save                : function () {
    method            = this.task.id ? "updateTask" : "createTask";
    return this.queue[method](this.task);
  }
};

let TaskFactory       = function TaskFactory(queue_name, task_name) {
  queue               = Queue(queue_name);
  task                = TaskFactory(task_name, queue);

};
Task.STATUS           = {
  NEW                 : STATUS_NEW,
  READY               : STATUS_READY,
  FAILED              : STATUS_FAILED,
  SUCCESS             : STATUS_SUCCESS,
  CANCELLED           : STATUS_CANCELLED
};
Task.PRIORITY         = {
  LOW                 : PRIORITY_MAP["low"],
  NORMAL              : PRIORITY_MAP["normal"],
  MEDIUM              : PRIORITY_MAP["medium"],
  HIGH                : PRIORITY_MAP["high"],
  CRITICAL            : PRIORITY_MAP["critical"]
};

module.exports        = TaskFactory;
