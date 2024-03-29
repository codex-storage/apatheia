import std/os

import chronicles
import chronos
import chronos/threadsync
import chronos/unittest2/asynctests
import taskpools

import apatheia/queues
import apatheia/jobs
import apatheia/memretainers

proc addNumsRaw(a, b: float): float =
  os.sleep(50)
  return a + b

proc addNums(jobResult: JobResult[float], a, b: float) =
  let res = addNumsRaw(a, b)
  discard jobResult.queue.send((jobResult.id, res,))

proc addNumsIncorrect(jobResult: JobResult[float], vals: openArray[float]): float =
  discard

proc addNumValues(jobResult: JobResult[float], base: float, vals: OpenArrayHolder[float]) =
  os.sleep(100)
  var res = base
  for x in vals.toOpenArray():
    res += x
  discard jobResult.queue.send((jobResult.id, res,))

proc strCompute(jobResult: JobResult[int], vals: OpenArrayHolder[char]) =
  discard jobResult.queue.send((jobResult.id, vals.size,))

proc addStrings(jobResult: JobResult[float], vals: OpenArrayHolder[string]) =
  discard

suite "async tests":

  var tp = Taskpool.new(num_threads = 2) # Default to the number of hardware threads.

  asyncTest "cannot return value":
    check not compiles(await jobs.submit(addNums(1.0, 2.0,)))

  asyncTest "test":
    var jobs = newJobQueue[float](taskpool = tp)

    let res = await jobs.submit(addNums(1.0, 2.0,))

    check res == 3.0

  asyncTest "testing seq":
    var jobs = newJobQueue[float](taskpool = tp)
    let res = await jobs.submit(addNumValues(10.0, @[1.0.float, 2.0]))
    check res == 13.0

  asyncTest "testing string":
    var jobs = newJobQueue[int](taskpool = tp)
    let res = await jobs.submit(strCompute("hello world!"))
    check res == 12

  asyncTest "testing arrays":
    var jobs = newJobQueue[float](taskpool = tp)
    let fut1 = jobs.submit(addNumValues(10.0, @[1.0.float, 2.0]))
    let fut2 = jobs.submit(addNumValues(20.0, @[3.0.float, 4.0]))
    check retainedMemoryCount() == 2
    let res1 = await fut1
    let res2 = await fut2
    check res1 == 13.0
    check res2 == 27.0
    check retainedMemoryCount() == 0

  asyncTest "don't compile":
    check not compiles(
      block:
        var jobs = newJobQueue[float](taskpool = tp)
        let job = jobs.submit(addStrings(@["a", "b", "c"]))
    )
