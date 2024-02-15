import std/os

import chronicles
import chronos
import chronos/threadsync
import chronos/unittest2/asynctests
import taskpools

import apatheia/queues
import apatheia/jobs

proc addNumsRaw(a, b: float): float =
  os.sleep(50)
  return a + b

proc addNums(jobResult: JobResult[float], a, b: float) =
  let res = addNumsRaw(a, b)
  discard jobResult.queue.send((jobResult.id, res,))

proc addNumValues(jobResult: JobResult[float], vals: openArray[float]): float =
  os.sleep(100)
  result = 0.0
  for x in vals:
    result += x

suite "async tests":

  var tp = Taskpool.new(num_threads = 2) # Default to the number of hardware threads.

  asyncTest "test":
    var jobs = newJobQueue[float](taskpool = tp)

    let res = await jobs.submit(addNums(1.0, 2.0,))

    check res == 3.0

  # asyncTest "test":
  #   var jobs = newJobQueue[float](taskpool = tp)
  #   let res = await jobs.submit(addNumValues([1.0, 2.0]))
  #   check res == 3.0

