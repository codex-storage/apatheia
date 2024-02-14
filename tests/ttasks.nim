import std/os

import chronos
import chronos/threadsync
import chronos/unittest2/asynctests
import taskpools

import apatheia/queues
import apatheia/tasks

## todo: setup basic async + threadsignal + taskpools example here
## 


proc addNums(a, b: float): float {.asyncTask.} =
  os.sleep(500)
  echo "adding: ", a, " + ", b
  return a + b

suite "async tests":
  var tp = Taskpool.new(num_threads = 2) # Default to the number of hardware threads.
  asyncTest "test":
    var jobs = newJobQueue[float](taskpool = tp)
    echo "\nstart"
    let res = await jobs.submit(addNums(1.0, 2.0,))
    echo "result: ", res.repr
    check true
