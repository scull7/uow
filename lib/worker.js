var Task          = require('./task.js');
var LockError     = require('uow-lock').LockError;

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
  this.queue      = queue;
  this.listeners  = {};

  this.Task       = options.Task || Task;
}

Worker.prototype.taskReady    = function(taskType, taskId) {

  this.queue.taskLock(this.id, taskId)

  .then(function(task) {
    task  = this.Task.dePickle(task, this.queue);

    this.emit(taskType, this.id, task);

  }.bind(this))

  // Ignore lock acquisition errors.
  .catch(LockError, function() {});
};

Worker.prototype.hasListenerFor = function(evName) {
  return this.listeners.hasOwnProperty(evName);
};

Worker.prototype.emit = function (evName) {
  var cbArgs  = Array.prototype.slice.call(arguments, 1);

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
    throw new TypeError('InvalidHandler');
  }

  this.listeners[evName]  = handler;

  return this;
};


module.exports  = Worker;
