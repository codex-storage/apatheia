import std/os

import chronos
import chronos/threadsync
import chronos/unittest2/asynctests
import taskpools

import apatheia/tasks

proc addNums(a, b: float): float {.asyncTask.} =
  os.sleep(50)
  return a + b

proc addNumValues(vals: openArray[float]): float {.asyncTask.} =
  os.sleep(100)
  result = 0.0
  for x in vals:
    result += x

suite "async tests":
  var tp = Taskpool.new(num_threads = 2) # Default to the number of hardware threads.
  var jobsVar = newJobQueue[float](taskpool = tp)

  proc getJobs(): JobQueue[float] =
    {.cast(gcsafe).}:
      jobsVar

  asyncTest "test addNums":
    let jobs = getJobs()
    let res = await jobs.submit(addNums(1.0, 2.0,))
    check res == 3.0

  asyncTest "test addNumValues":
    let jobs = getJobs()
    let args = @[1.0, 2.0, 3.0]
    let res = await jobs.submit(addNumValues(args))
    check res == 6.0
