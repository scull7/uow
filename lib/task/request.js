var later             = require('later');
var Task              = require('../task.js');
var Priority          = require('./priority.js');

var BACKOFF_ALGOS         = [
  'fixed', // wait for the task delay between retries.
  'linear' // task delay * attempts between retries.
];

function TaskRequest(name, queue, TaskConstructor) {
  if(!TaskConstructor) {
    TaskConstructor   = Task;
  }

  this.queue          = queue;
  this.task           = new TaskConstructor(name, queue);
}
TaskRequest.prototype = {
  /**
   * Set the task specific information.
   * ----------------------------------
   * @param {*} data
   * @return {TaskRequest}
   */
  data: function(data) {
    this.task.data    = data;
    return this;
  },

  /**
   * Set the task to run at a later date based upon a given `later` expression.
   * --------------------------------------------------------------------------
   * @param {string} expression
   * @return {TaskRequest}
   */
  later: function (expression) {

    var schedule      = later.parse.text(expression);
    var next          = later.schedule(schedule).next(1);

    this.task.after        = next.getTime();

    return this;
  },

  /**
   * Delay the running of this task.
   * -------------------------------
   * Will delay the task for `x` milliseconds after the scheduled time.
   * @param {int} milliseconds
   * @return {TaskRequest}
   */
  delay: function (milliseconds) {

    var delay         = parseInt(milliseconds, 10);

    if (isNaN(delay)) {
      throw new TypeError('InvalidDelay');
    }

    this.task.delay   = delay;

    return this;
  },

  /**
   * Specific max number of task run attempts.
   * -----------------------------------------
   * @param {int} count
   * @return {TaskRequest}
   */
  attempts: function (count) {
    var max           = parseInt(count, 10);

    if (isNaN(max)) {
      throw new TypeError('InvalidMaxAttempts');
    }

    this.task.attempts.max = max;

    return this;
  },

  /**
   * Specify the tasks run priority.
   * -------------------------------
   * @param {int} priority
   * @return {TaskRequest}
   */
  priority: function (priority) {
    var level         = Priority.MAP[priority] || parseInt(priority, 10);

    if(isNaN(level)) {
      throw new TypeError('InvalidPriority');
    }
    this.task.priority  = level;

    return this;
  },

  /**
   * Specify the retry back-off algoritm.
   * ------------------------------------
   * @param {string} algo - the algorithm name.
   * @return {TaskRequest}
   */
  backoff: function (algo) {

    if( BACKOFF_ALGOS.indexOf(algo) < 0 ) {
      throw new TypeError('InvalidBackoffAlgorithm');
    }
    this.task.backoff = algo;

    return this;
  },

  /**
   * Send this task request to the queue.
   * ------------------------------------
   * @return {Promise::Task}
   */
  send: function () {
    return this.queue.taskAdd(this.task);
  }
};

module.exports  = TaskRequest;
