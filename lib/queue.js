/**
 * This is the Queue interface.
 * ============================
 * - Queue needs to emit "task::ready" events when a task becomes ready.
 * - @TODO handle worker disconnection events.
 * - @TODO send out alive checks?
 * - @TODO remove the local lock store registry.
 */
var uuid          = require('uuid');
var inherits      = require('util').inherits;
var EventEmitter  = require('events').EventEmitter;
var LockError     = require('./lock/exception.js');
var Task          = require('./task.js');
var registry      = {};
var locks         = {};

function taskUpdate(self, status, eventName) {

  return function(workerId, taskId, response) {

    return self.taskGetById(taskId, workerId)

    .then(function(task) {

      task.status         = status;
      task.data.response  = response;

      return self.store.updateTask(task);

    })

    .then(function(task) {

      self.emit('task::' + eventName, task);

      return task;

    });

  };
}

/**
 * Constructor for a Queue object.
 * -------------------------------
 * @constructor {Queue}
 * @param {Store} store
 */
function Queue(store) {
  // optional new pattern.
  if(! (this instanceof Queue) ) {
    return new Queue(store);
  }

  this.store    = store;
  workerNotify  = this.workerNotify.bind(this)

  store.on('ready', function(task) {
    workerNotify(task);
  });

  /**
   * Notify the Queue that the task has finished processing.
   * -------------------------------------------------------
   * - emit "task::finished"
   * @param {string} workerId
   * @param {string} taskId
   * @param {Object} response - any data to add as the task response.
   * @return {Promise::task}
   */
  this.taskComplete   = taskUpdate(this, Task.STATUS.SUCCESS, 'finished');

  /**
   * Notify the Queue that the task has errored.
   * -------------------------------------------
   * - emit "task::failed"
   * @param {stirng} workerId
   * @param {string} taskId
   * @param {Object} response - any data to add as the task response.
   * @return {Promise::Task}
   */
  this.taskFail       = taskUpdate(this, Task.STATUS.FAILED, 'failed');

  /**
   * Notify the Queue that the task has been cancelled.
   * --------------------------------------------------
   * - emit "task::cancelled"
   * @param {string} workerId
   * @param {string} taskId
   * @param {Object} response - any data to add as the task response.
   * @return {Promise::Task}
   */
  this.taskCancel     = taskUpdate(this, Task.STATUS.CANCELLED, 'cancelled');
}

inherits(Queue, EventEmitter);

/**
 * Ensure that the worker has access to the task.
 * ----------------------------------------------
 * - task is not locked by another worker.
 * - task is locked by the given worker.
 * @param {string} workerId
 * @param {string} taskId
 * @return {Promise::task}
 * @throws {LockError}
 */
Queue.prototype.taskGetById = function(workerId, taskId) {
  this.taskAccessAllowed(taskId, workerId);

  return this.store.getTaskById(taskId);
};

/**
 * Add a task object into the queue.
 * ---------------------------------
 * @param {Task} task
 * @return {Promise::Task}
 */
Queue.prototype.taskAdd = function(task) {
  return this.store.createTask(task);
};

/**
 * Ensure that the worker has access to the task.
 * ----------------------------------------------
 * - task is not locked by another worker.
 * - task is locked by the given worker.
 * @param {string} workerId
 * @param {string} taskId
 * @return {void}
 * @throws {LockError}
 */
Queue.prototype.taskAccessAllowed = function (workerId, taskId) {
  // @TODO - call the store to ensure we have proper lock information.

  lock  = locks[taskId];

  if(
    lock &&
    lock.expiration < (new Date().getTime()) &&
    lock !== lock.workerId
  ) {
    throw LockError('NotOwnTask');
  }

};

/**
 * Attempt to acquire a lock for the given task.
 * ---------------------------------------------
 * - emit "task::locked"
 * - lock is encrypted using the worker key.
 * - lock relies upon the Queue store to ensure atomicity.
 * @param {string} workerId
 * @param {string} taskId
 * @return {Promise::Task}
 */
Queue.prototype.taskLock  = function (workerId, taskId) {

  return this.taskGetById(taskId, workerId)

  .then(function(task) {

    return this.store.lockTask(workerId, task.id);

  }.bind(this))

  .then(function(task) {

    this.locks[task.id] = {
      workerId:   workerId,
      expiration: task.time + task.ttl
    };

    this.emit('task::locked', task);

    return task;

  }.bind(this));

};

/**
 * Attempt to release the lock on a task.
 * --------------------------------------
 * @param {string} workerId
 * @param {string} taskId
 * @return {Promise::Task}
 * @throws {LockError}
 */
Queue.prototype.taskUnlock  = function(workerId, taskId) {

  return this.taskGetById(taskId, workerId)

  .then(function(task) {

    return this.store.unlockTask(workerId, taskId);

  }.bind(this))

  .then(function(task) {

    delete this.locks[task.id];

    this.emit('task::unlocked', task);

    return task;

  }.bind(this));
}

/**
 * Notify the Queue that the task processing has progressed.
 * ---------------------------------------------------------
 * - emit "task::progress"
 * @param {string} workerId
 * @param {string} taskId
 * @param {ProgressObject} progress
 * @return {void}
 */
Queue.prototype.taskProgress  = function(workerId, taskId, progress) {

  return this.taskGetById(taskId, workerId)

  .then(function (task) {

    task.progress = progress;
    return this.store.updateTask(task);

  }.bind(this))

  .then(function(task) {

    this.emit('task::progress', task);
    return task;

  }.bind(this));

};

/**
 * Register a task worker
 * -----------------------
 * - emit "worker::registered"
 * - Returns a key (UUID v4) to each registered worker.
 * @param {Array.<string>} taskTypes
 * @param {Worker} worker
 * @return {string}
 */
Queue.prototype.workerRegister  = function(taskTypes, worker) {
  var key         = uuid.v4();
  var i, eventName;

  registry[key]   = {
    worker: worker,
    types:  taskTypes
  };

  this.on('task::ready', worker.taskReady.bind(worker));

  return key;
};

/**
 * Notify workers that there is a task ready to be processed.
 * ----------------------------------------------------------
 * @param {Task} task
 * @return {Queue}
 */
Queue.prototype.workerNotify  = function(task) {

  this.emit('task::ready', task);

  return this;
};

/**
 * Return a list of current workers with their current status.
 * -----------------------------------------------------------
 * @return {QueueStatus}
 */
Queue.prototype.workerStatus  = function() {
  throw new Error('NotImplemented');
}

module.exports  = Queue;
