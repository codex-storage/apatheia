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
  return a + b

proc addNumValues(vals: openArray[float]): float {.asyncTask.} =
  os.sleep(100)
  result = 0.0
  for x in vals:
    result += x

suite "async tests":
  var tp = Taskpool.new(num_threads = 2) # Default to the number of hardware threads.

  asyncTest "test addNums":
    var jobs = newJobQueue[float](taskpool = tp)
    let res = await jobs.submit(addNums(1.0, 2.0,))
    check res == 3.0

  asyncTest "test addNumValues":
    var jobs = newJobQueue[float](taskpool = tp)
    let args = @[1.0, 2.0, 3.0]
    let res = await jobs.submit(addNumValues(args))
    check res == 6.0
