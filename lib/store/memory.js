var inherits      = require('util').inherits;
var uuid          = require('uuid');
var bluebird      = require('bluebird');
var EventEmitter  = require('events').EventEmitter;
var TaskLock      = require('uow-lock');
var LockError     = TaskLock.LockError;

// @TODO - implement a search for new ready tasks every tick.

function MemoryStore () {
  this.store  = {};
}

inherits(MemoryStore, EventEmitter);

/**
 * Store a represention of the given task object.
 * @param {Task}
 * @return {Promise::Task}
 * @throws {TypeError}
 */
MemoryStore.prototype.createTask = function (task) {
  if (task.id) {
    return bluebird.reject(new TypeError('InvalidTaskObject'));
  }
  task.id               = uuid.v4();

  if (typeof task.pickle === 'function') {
    task                = task.pickle();
  }
  this.store[task.id]   = task;

  return bluebird.resolve(task);
};

/**
 * Update a task's stored representation.
 * --------------------------------------
 * @param {string} workerId
 * @param {Task}
 * @return {Promise::Task}
 *@throws {TypeError}
 */
MemoryStore.prototype.updateTask = function (workerId, task) {
  if(!task.id) {
    return bluebird.reject(new TypeError('InvalidTaskObject'));
  }

  return this.getTaskById(task.id)

  .then(function(stored_task) {

    if(

      TaskLock.isTaskLocked(stored_task) &&
      !TaskLock.isLockHolder(stored_task, workerId)

    ) {
      throw new LockError('TaskLocked');
    }

    this.store[task.id] = task;

    return task;

  }.bind(this));

};

/**
 * Retrieve a task object by its assigned identifier.
 * --------------------------------------------------
 * - If the task is locked only allowed the lock holder to access the task.
 * @param {string} id
 * @return {Promise::Task}
 * @throws {TypeError}
 */
MemoryStore.prototype.getTaskById = function (id) {
  if(!id) {
    return bluebird.reject(new TypeError('TaskIdNotProvided'));
  }
  return bluebird.resolve(this.store[id] || null);
};

/**
 * Attempt to acquire a lock for the given task ID.
 * ------------------------------------------------
 * @param {string} workerId
 * @param {string} taskId
 * @param {int} timeToLive
 * @return {Promise::Task}
 * @throws {TypeError}
 * @throws {LockError}
 */
MemoryStore.prototype.lockTask = function (workerId, taskId, timeToLive) {
  if(!workerId) {
    return bluebird.reject(new TypeError('WorkerIdNotProvided'));
  }
  if(!taskId) {
    return bluebird.reject(new TypeError('TaskIdNotProvided'));
  }

  return this.getTaskById(taskId)

  .then(TaskLock.acquire.bind(null, timeToLive, workerId))

  .then(this.updateTask.bind(this, workerId));

};

/**
 * Release a lock from a task.
 * ---------------------------
 * @param {string} workerId
 * @param {string} taskId
 * @return {Promise::Task}
 * @throws {TypeError}
 */
MemoryStore.prototype.unlockTask  = function (workerId, taskId) {
  if(!workerId) {
    return bluebird.reject(new TypeError('WorkerIdNotProvided'));
  }
  if(!taskId) {
    return bluebird.reject(new TypeError('TaskIdNotProvided'));
  }

  return this.getTaskById(taskId)

  .then(TaskLock.release.bind(null, workerId))

  .then(this.updateTask.bind(this, workerId));
};

module.exports  = MemoryStore;
