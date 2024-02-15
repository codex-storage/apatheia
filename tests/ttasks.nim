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
  os.sleep(100)
  # info "adding: ", a=a, b=b
  return a + b

proc addNumValues(vals: openArray[float]): float {.asyncTask.} =
  os.sleep(100)
  result = 0.0
  for x in vals:
    result += x
  # echo "adding sums: ", vals

suite "async tests":
  var tp = Taskpool.new(num_threads = 2) # Default to the number of hardware threads.

  asyncTest "test addNums":
    var jobs = newJobQueue[float](taskpool = tp)
    echo "\nstart"
    let res = await jobs.submit(addNums(1.0, 2.0,))
    echo "result: ", res.repr
    check true

  asyncTest "test addNumValues":
    var jobs = newJobQueue[float](taskpool = tp)
    echo "\nstart"
    let args = @[1.0, 2.0, 3.0]
    let res = await jobs.submit(addNumValues(args))
    echo "result: ", res.repr
    check true
