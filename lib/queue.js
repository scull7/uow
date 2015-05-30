var
  MemoryStore       = require("./store/memory"),
  queues            = {},
;
var queues          = {}

function Queue(name, store) {
  this.name         = name;
  this.store        = store;
}
Queue.prototype     = {

  createTask        : function (task) {
    return this.store.createTask(task);
  },

  updateTask        : function (task) {
    return this.store.updateTask(task);
  }
};

function QueueFactory(name, store) {
  var queue         = queues[name];

  if(!store) {
    store           = MemoryStore();
  }

  if(!queue) {
    queue           = queues[name] = new Queue(name, store);
  }

  return queue;
}

module.exports      = QueueFactory;
