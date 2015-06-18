var
  uuid        = require("uuid"),
  bluebird    = require("bluebird"),
  taskLock    = require("../task/lock.js")
;

// @TODO - ***ensure that only the key holder may retrieve a locked task.***
// @TODO - ***ensure that only the key holder may update a locked task.***
// @TODO - implement a search for new ready tasks every tick.

function MemoryStore () {
  this.store  = {};
}
MemoryStore.prototype = {

  /**
   * Store a represention of the given task object.
   * @param {Task}
   * @return {Promise::Task}
   * @throws {TypeError}
   */
  createTask: function (task) {
    if (task.id) {
      return bluebird.reject(new TypeError("InvalidTaskObject"));
    }
    task.id               = uuid.v4();
    this.store[task.id]   = task;

    return bluebird.resolve(task);
  },

  /**
   * Update a task's stored representation.
   * --------------------------------------
   * @param {Task}
   * @return {Promise::Task}
   * @throws {TypeError}
   */
  updateTask: function (task) {
    if(!task.id) {
      return bluebird.reject(new TypeError("InvalidTaskObject"));
    }
    this.store[task.id]   = task;

    return bluebird.resolve(task);
  },

  /**
   * Retrieve a task object by its assigned identifier.
   * --------------------------------------------------
   * - If the task is locked only allowed the lock holder to access the task.
   * @param {string} id
   * @return {Promise::Task}
   * @throws {TypeError}
   */
  getTaskById: function (id) {
    if(!id) {
      return bluebird.reject(new TypeError("TaskIdNotProvided"));
    }
    return bluebird.resolve(this.store[id] || null);
  },

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
  lockTask: function (workerId, taskId, timeToLive) {
    if(!workerId) {
      return bluebird.reject(new TypeError('WorkerIdNotProvided'));
    }
    if(!taskId) {
      return bluebird.reject(new TypeError("TaskIdNotProvided"));
    }

    return this.getTaskById(taskId)

    .then(taskLock.acquire.bind(null, timeToLive, workerId))

    .then(this.updateTask.bind(this));

  },

  /**
   * Release a lock from a task.
   * ---------------------------
   * @param {string} workerId
   * @param {string} taskId
   * @return {Promise::Task}
   * @throws {TypeError}
   */
  unlockTask: function (workerId, taskId) {
    if(!workerId) {
      return bluebird.reject(new TypeError('WorkerIdNotProvided'));
    }
    if(!taskId) {
      return bluebird.reject(new TypeError('TaskIdNotProvided'));
    }

    return this.getTaskById(taskId)

    .then(taskLock.release.bind(null, workerId))

    .then(this.updateTask.bind(this));
  }
};

module.exports  = MemoryStore;
