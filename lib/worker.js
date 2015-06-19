var LockError     = require('./lock/exception.js');

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
  this.queue      = queue
  this.listeners  = {};
}

Worker.prototype.taskReady    = function(taskType, taskId) {

  this.queue.taskLock(this.id, taskId)

  .then(function(task) {

    this.emit(taskType, this.id, task);

  }.bind(this))

  // Ignore lock acquisition errors.
  .catch(LockError, function() {});
};

Worker.prototype.hasListenerFor = function(evName) {
  return this.listeners.hasOwnProperty(evName);
};

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
  if(typeof handler !== 'function') {
    throw new TypeError('InvalidHandler')
  }

  this.listeners[evName]  = handler;

  return this;
};


module.exports  = Worker;
