var Status                = require('./task/status.js');
var Priority              = require('./task/priority.js');
var LockError             = require('uow-lock').LockError;

var DEFAULT_MAX_ATTEMPTS  = 1;
var DEFAULT_TASK_STATUS   = Status.NEW;
var DEFAULT_TASK_PRIORITY = Priority.NORMAL;
var DEFAULT_BACKOFF_ALGO  = 'fixed';

function Task(name, queue) {
  this.queue      = queue;
  this.id         = null;
  this.name       = name;
  this.status     = DEFAULT_TASK_STATUS;
  this.data       = {};
  this.after      = new Date().getTime();
  this.delay      = 0;
  this.priority   = DEFAULT_TASK_PRIORITY;
  this.attempts   = {
    failed        : 0,
    cancelled     : 0,
    timed_out     : 0,
    total         : 0,
    max           : DEFAULT_MAX_ATTEMPTS
  };
  this.backoff    = DEFAULT_BACKOFF_ALGO;
  this.schedule   = null;
}

function mustBePersisted(task, ErrorConstructor) {
  if(!ErrorConstructor) {
    ErrorConstructor  = TypeError;
  }
  if(!task.id) {
    throw new ErrorConstructor('TaskNotPersisted');
  }
}

/**
 * Given a pickled task  dataset generate a Task object.
 * -----------------------------------------------------
 * @param {Object} pickledTask
 * @return {Task}
 */
Task.dePickle = function(pickledTask, queue) {
  var task      = new Task(pickledTask.name, queue);
  task.id       = pickledTask.id;
  task.status   = pickledTask.status;
  task.data     = pickledTask.data;
  task.after    = pickledTask.after;
  task.delay    = pickledTask.delay;
  task.priority = pickledTask.priority;
  task.attempts = pickledTask.attempts;
  task.backoff  = pickledTask.backoff;
  task.schedule = pickledTask.schedule;

  return task;
};

/**
 * Return the persistable dataset for this task.
 * ---------------------------------------------
 * @return {Object}
 */
Task.prototype.pickle  = function() {
  return {
    id:         this.id,
    name:       this.name,
    status:     this.status,
    data:       this.data,
    after:      this.after,
    delay:      this.delay,
    priority:   this.priority,
    attempts:   this.attempts,
    backoff:    this.backoff,
    schedule:   this.schedule
  };
};

/**
 * Attempt to acquire a lock on this task.
 * @param {string} workerId
 * @return {Promise::Task}
 * @throws {LockError}
 */
Task.prototype.lock     = function(workerId) {
  mustBePersisted(this, LockError);
  return this.queue.taskLock(workerId, this.id);
};

/**
 * Mark the task as sucessfully run.
 * ---------------------------------
 * @param {string} workerId
 * @param {Object} response
 * @return {Promise::Task}
 */
Task.prototype.complete  = function(workerId, response) {
  mustBePersisted(this);
  return this.queue.taskComplete(workerId, this.id, response);
};

/**
 * Yield this instance of the task but run again according to the schedule.
 * ------------------------------------------------------------------------
 * @param {string} workerId
 * @param {Object} response
 * @return {Promise::Task}
 */
Task.prototype.yield  = function(workerId, response) {
  mustBePersisted(this);
  return this.queue.taskYield(workerId, this.id, response);
};

/**
 * Mark the task as failed.
 * ------------------------
 * @param {string} workerId
 * @param {Object} response
 * @return {Promise::Task}
 */
Task.prototype.fail     = function(workerId, response) {
  mustBePersisted(this);
  return this.queue.taskFail(workerId, this.id, response);
};

/**
 * Cancel this task.
 * -----------------
 * @param {string} workerId
 * @param {Object} response
 * @return {Promise::Task}
 */
Task.prototype.cancel   = function(workerId, response) {
  mustBePersisted(this);
  return this.queue.taskCancel(workerId, this.id, response);
};

/**
 * Update the progress of a task.
 * ------------------------------
 * @param {string} workerId
 * @param {ProgressObject} progress
 * @return {Promise::Task}
 */
Task.prototype.progress = function(workerId, progress) {
  mustBePersisted(this);
  return this.queue.taskProgress(workerId, this.id, progress);
};

Task.STATUS     = Status;
Task.PRIORITY   = Priority;

module.exports  = Task;
