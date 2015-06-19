var LockError     = require('lock/exception.js');

/**
 * Initialize and Register a new worker to the given queue.
 * --------------------------------------------------------
 * @constructor
 * @param {Queue} queue
 * @param {Object} options {
 *    types: {Array.<string>}
 * }
 */
function Worker(queue, options) {
  this.id = queue.workerRegister(options.types, this);
  this.listeners  = {};
}

Worker.prototype.taskReady    = function(task) {
  queue.taskLock(this.id, task.id)

  .then(function(task) {

    this.emit(task.name, this.id, task);

  }.bind(this))

  // Ignore lock acquisition errors.
  .catch(LockError, function() {});
}

Worker.prototype.hasListenerFor(evName) {
  return this.listeners.hasOwnProperty(evName);
}

Worker.prototype.emit = function (evName) {
  cbArgs  = Array.prototype.slice.call(arguments, 1);

  if(this.hasListenerFor(evName)) {
    this.listeners[evName].apply(null, cbArgs);
  }
  return this;
};

Worker.prototype.on = function(evName, handler) {
  if(this.hasListenerFor(evName)) {
    throw new Error('DuplicateListener');
  }
  this.listeners[evName]  = handler;

  return this;
};


module.exports  = Worker;
