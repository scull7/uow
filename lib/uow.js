var Queue         = require('./queue');
var TaskRequest   = require('./task/request/factory.js');
var Worker        = require('./worker.js');
var MemoryStore   = require('./store/memory.js');

// @TODO - implement concurrency on the task request.
// @TODO - implement task ready search retry back-off algorithm.

/**
 * A list of queue singletons.
 */
var queues        = {};

/**
 * Create a new queue and store it in the queue list at the given namespace.
 * -------------------------------------------------------------------------
 * @param {string} name
 * @param {Object} options
 * @return {Queue}
 */
function createQueue(name, options) {
  if(!options.store) {
    options.store = new MemoryStore();
  }
  queues[name] = new Queue(name, options.store);

  return queues[name];
}

/**
 * Initialize a unit of work queue.
 * --------------------------------
 * @param {string} name
 * @param {Object} options {
 *    store: {Store}
 * }
 * @return {uow}
 */
function init(name, options) {
  queue   = queues[name] || createQueue(name, options);

  return {
    /**
     * Initiate a new task request.
     * ----------------------------
     * @param {string} name
     * @return {TaskRequest}
     */
    requestTask:    function(name) {
      return new TaskRequest(name, queue, options.TaskClass);
    },

    /**
     * Register a new task worker.
     * ---------------------------
     * @param {Object} options {
     *    types: {Array.<string>}
     * }
     * @return {Worker}
     */
    registerWorker: function(options) {
      return new Worker(queue, options);
    }

  };
}

module.exports = init;
