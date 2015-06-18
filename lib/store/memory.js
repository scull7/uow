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

  createTask: function (task) {
    if (task.id) {
      return bluebird.reject(new TypeError("InvalidTaskObject"));
    }
    task.id               = uuid.v4();
    this.store[task.id]   = task;

    return bluebird.resolve(task);
  },

  updateTask: function (task) {
    if(!task.id) {
      return bluebird.reject(new TypeError("InvalidTaskObject"));
    }
    this.store[task.id]   = task;

    return bluebird.resolve(task);
  },

  getTaskById: function (id) {
    if(!id) {
      return bluebird.reject(new TypeError("TaskIdNotProvided"));
    }
    return bluebird.resolve(this.store[id] || null);
  },

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
