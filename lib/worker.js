var inherits      = require('util').inherits
var EventEmitter  = require('events').EventEmitter;
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
}
inherits(Worker, EventEmitter);

Worker.prototype.taskReady    = function(task) {
  queue.taskLock(this.id, task.id)

  .then(function(task) {

    this.emit(task.name, this.id, task);

  }.bind(this))

  // Ignore lock acquisition errors.
  .catch(LockError, function() {});
}


module.exports  = Worker;
