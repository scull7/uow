/**
 * This is the Queue interface.
 * ============================
 * - Queue needs to emit "task::ready" events when a task becomes ready.
 * - @TODO handle worker disconnection events.
 * - @TODO send out alive checks?
 * - @TODO remove the local lock store registry.
 */
var uuid          = require('uuid');
var later         = require('later');
var inherits      = require('util').inherits;
var isArray       = require('util').isArray;
var EventEmitter  = require('events').EventEmitter;
var LockError     = require('./lock/exception.js');
var Task          = require('./task.js');

function taskUpdate(self, status, eventName) {

  return function(workerId, taskId, response) {

    return self.taskLock(workerId, taskId)

    .then(function(task) {

      task.status         = status;

      if(!task.response) {
        task.response     = [];
      }
      if(!isArray(task.response)) {
        task.response     = [ task.response ]
      }
      task.response.push(response);

      return self.store.updateTask(workerId, task);

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

  this.registry = {};

  this.store    = store;
  workerNotify  = this.workerNotify.bind(this)

  this.store.on('ready', function(task) {
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
 * Retrieve a task object by identifier.
 * -------------------------------------
 * @param {string} taskId
 * @return {Promise::task}
 * @throws {LockError}
 */
Queue.prototype.taskGetById = function(taskId) {

  return this.store.getTaskById(taskId)

  .then(function(stored_task) {

    return Task.dePickle(stored_task, this);

  }.bind(this));

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

  return this.taskGetById(taskId)

  .then(function(task) {

    return this.store.lockTask(workerId, task.id);

  }.bind(this))

  .then(function(task) {

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

  return this.taskGetById(taskId)

  .then(function(task) {

    return this.store.unlockTask(workerId, taskId);

  }.bind(this))

  .then(function(task) {

    this.emit('task::unlocked', task);

    return task;

  }.bind(this));
}

/**
 * Notify the Queue that the task instance is processed.
 * -----------------------------------------------------
 * - emit "task::finished"
 * @param {string} workerId
 * @param {string} taskId
 * @param {Object} response - any data to add as the task response.
 * @return {Promise::Task}
 * @throws {TypeError}
 */
Queue.prototype.taskYield = function(workerId, taskId, response) {

  return this.taskLock(workerId, taskId)

  .then(function(task) {

    if(!task.schedule) {
      throw new TypeError('TaskNotScheduled');
    }

    // calculate next schedule.
    var schedule  = later.parse.text(task.schedule);
    var next      = later.schedule(schedule).next(2);

    task.after    = next[1].getTime();

    return this.store.updateTask(workerId, task);

  }.bind(this))

  .then(function(task) {

    this.emit('task::finished', task);
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

  return this.taskLock(workerId, taskId)

  .then(function (task) {

    task.progress = progress;

    return this.store.updateTask(workerId, task);

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
  var key             = uuid.v4();
  var i, eventName;

  this.registry[key]  = {
    worker: worker,
    types:  taskTypes
  };

  taskHandler = (function(handler, typeList) {

    return function(taskType, taskId) {

      if(typeList.indexOf(taskType) > -1) {
        handler(taskType, taskId);
      }

    };

  }(worker.taskReady.bind(worker), taskTypes));

  this.on('task::ready', taskHandler);

  return key;
};

/**
 * Notify workers that there is a task ready to be processed.
 * ----------------------------------------------------------
 * @param {Task} task
 * @return {Queue}
 * @throws {TypeError}
 */
Queue.prototype.workerNotify  = function(task) {

  if(!task.id) {
    throw new TypeError('TaskNotPersisted');
  }
  if(!task.name) {
    throw new TypeError('TaskTypeMissing');
  }

  this.emit('task::ready', task.name, task.id);

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
