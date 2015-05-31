var
  uuid        = require("uuid"),
  bluebird    = require("bluebird"),
  taskLock    = require("../task/lock.js")
;

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

  lockTask: function (id, time_to_live) {
    if(!id) {
      return bluebird.reject(new TypeError("TaskIdNotProvided"));
    }
    return this.getTaskById(id)
    .then( taskLock.acquire.bind(null, time_to_live) )
    .then( this.updateTask.bind(this) );
  }
};

function MemoryStoreFactory () {
  return new MemoryStore();
}

module.exports            = MemoryStoreFactory;
