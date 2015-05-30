var
  MemoryStore       = require("./store/memory")
;
let queues          = {}

let Queue           = function Queue(name) {

};

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

function QueueFactory(name, store = MemoryStore) {
  let queue         = queues[name];

  if(!queue) {
    queue           = queues[name] = new Queue(name, store);
  }

  return queue;
}

module.exports      = QueueFactory;
