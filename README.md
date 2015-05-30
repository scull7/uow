[![Build Status](https://travis-ci.org/scull7/uow.svg)](https://travis-ci.org/scull7/uow)
[![Coverage Status](https://coveralls.io/repos/scull7/uow/badge.svg)](https://coveralls.io/r/scull7/uow)
[![Code Climate](https://codeclimate.com/github/scull7/uow/badges/gpa.svg)](https://codeclimate.com/github/scull7/uow)

# uow
a simple, multi-backend unit of work queue.

## Usage

### Creating a Task.
```javascript
var uow       = require("uow");

// This will create a basic memory queue.
// If you would like a db queue then, you must supply a storage driver.
// `uow.init("my-jobs", { store: MyFancyStoreObject })`
uow.init("my-tasks");

var task  = uow.Task("my-tasks", "task-name", {
  example : "This is an example data point."
  other   : "another example data point."
});

// Using later you can schedule the task in the future.
task  = task.later(later_js_expression);

// You can delay the task for a specified time.
// ***Note*** when setting a `later` and `delay` the task will wait `delay`
//  milliseconds after the `later` schedule date.
task  = task.delay(number_of_milliseconds);

// You can set a priority on the job.
// The following priorities are available: {
//   low      : 10
//   normal   : 0
//   medium   : -5
//   high     : -10
//   critical : -15
// }
task  = task.priority("high");

// You can specify the number of retry attempts.
// Default is zero (0).
task  = task.attempts(3);

// You can specify a back-off algorithm
// Default is `fixed`
task  = task.backoff( true );

// Once you have seasoned to your liking then save your task.
task.save()
.then(function (task) {
  console.log( task.id );
})
.catch(function (e) {
  console.log( e );
});

```

#### Task Schema
```javascript
{
  id          : "110ec58a-a0f2-4ac4-8393-c866d813b8d1", // UUID v4 of this task.
  name        : "task-name", // type of task.
  status      : "ready", // task is ready to be run.
  data        : { // user supplied data.
    example   : "This is an example data point.",
    other     : "another example data point."
  },
  delay       : 0, // how long to delay the run of this task after, after date.
  after       : 1432956883000, // task available to run after this date.
  priority    : 0, // normal priority.
  attempts    : {
    failed    : 0, // number of times the task failed.
    cancelled : 0, // number of times the task was started but cancelled.
    timed_out : 0, // number of times the task timed out.
    total     : 0, // total number of attempts.
    max       : 2 // maximum number of times to attempt this task.
  },
  backoff     : "fixed" // name of the back-off algorithm.
}
```

#### Task Status List
* ***Ready***     - Task is ready to run if now is greater than `after` date.
* ***Failed***    - Task has failed and should not be retried.
* ***Success***   - Task has been successfully completed.
* ***Cancelled*** - Task has been cancelled.

### Processing Tasks
```javascript
// @TODO provide a polling interval. by default it will poll as fast as possible.
var worker  = uow.Worker([ "task-name", "email" ])

worker.on("process task-name", function (job, done) {
  // ... do stuff here.
  done();
});
```
When you call uow.Worker it will start looking into the store for
tasks to process.

  1. Query for unlocked (lock expired) "pending" tasks.
  2. Request lock on task.
  3. Notify worker of task.
  4. Wait for worker to complete task.

Once it finds a task it will issue a lock request for that task.
```javascript
// Default time to live is 30 seconds.
store.getLock(task, time_to_live = 30000);
.then(function (task) {
  worker.emit("process "+task.name, task, callback);
});
```

#### Worker List Schema
// @TODO add performance statistics.
```javascript
{
  id          : "2a31cb0-1432-11e1-8558-0b488e4fc115", // UUID of the worker.
  status      : "waiting", // worker is waiting assignment.
  last_active : 1432957521000, // worker has been idle since this time.
}
```

#### Worker Status List
* ***Waiting***     - Worker is waiting on task assignment.
* ***Processing***  - Worker is busy processing a task.
* ***Errored***     - Worker has failed.
* ***Sleeping***    - Worker has requested some time off.
* ***Quit***        - Worker has gone home for the day.
