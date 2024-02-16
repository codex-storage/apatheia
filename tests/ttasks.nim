import std/os

import chronos
import chronos/threadsync
import chronos/unittest2/asynctests
import taskpools

import apatheia/tasks
import apatheia/memretainers

proc addNums(a, b: float): float {.asyncTask.} =
  os.sleep(50)
  return a + b

proc addNumValues(vals: openArray[float]): float {.asyncTask.} =
  os.sleep(100)
  result = 0.0
  for x in vals:
    result += x

proc strCompute(val: openArray[char]): int {.asyncTask.} =
  ## note includes null terminator!
  return val.len()


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

  asyncTest "test strCompute":
    var jobs = newJobQueue[int](taskpool = tp)
    let res = await jobs.submit(strCompute("hello world!"))
    check res == 13 # note includes cstring null terminator

  asyncTest "testing openArrays":
    var jobs = newJobQueue[float](taskpool = tp)
    let fut1 = jobs.submit(addNumValues(@[1.0.float, 2.0]))
    let fut2 = jobs.submit(addNumValues(@[3.0.float, 4.0]))
    check retainedMemoryCount() == 2
    let res1 = await fut1
    let res2 = await fut2
    check res1 == 3.0
    check res2 == 7.0
    check retainedMemoryCount() == 0
