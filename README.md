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
// ***Note*** when setting a `later` and `delay` the last one will win.
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

// You can specify a backoff algorithm
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
