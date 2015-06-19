var isArray       = require('util').isArray;
var uuid          = require('uuid');
var Queue         = require('./queue.js');
var TaskRequest   = require('./task/request.js');
var TaskWorker    = require('./worker.js');
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
  options         = options || {};

  if(!options.store) {
    options.store = new MemoryStore();
  }

  return new Queue(options.store);
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

  if(!queues.hasOwnProperty(name)) {
    var queue     = createQueue(name, options);

    queues[name]  = {
      /**
       * Unique identifier for this queue.
       * ---------------------------------
       * @var {string}
       */
      id: uuid.v4(),

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
        if(!options || !options.types) {
          throw new TypeError('NoTypesSpecified');
        }
        var types = options.types

        if(typeof types === 'string') {
          types   = [ types ]
        }

        if(!isArray(types)) {
          throw new TypeError('TypesInvalid');
        }

        if(types.length < 1) {
          throw new TypeError('NoTypesSpecified')
        }

        options.types = types;

        return new TaskWorker(queue, options);
      }

    };
  }

  return queues[name];
}

module.exports = init;
