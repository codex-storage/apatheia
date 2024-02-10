import std/os

import chronos
import chronos/threadsync
import chronos/unittest2/asynctests
import taskpools

import apatheia/queues
import apatheia/jobs

## todo: setup basic async + threadsignal + taskpools example here
## 

proc addNumsRaw(a, b: float): float =
  os.sleep(500)
  echo "adding: ", a, " + ", b
  return a + b

proc addNums(queue: SignalQueue[(uint, float)], id: uint, a, b: float) =
  let res = addNumsRaw(a, b)
  discard queue.send((id, res,))

suite "async tests":

  # var tp = Taskpool.new(num_threads = 2) # Default to the number of hardware threads.
  # var queue = newSignalQueue[float]()

  var tp = Taskpool.new(num_threads = 2) # Default to the number of hardware threads.

  asyncTest "test":

    var jobs = newJobQueue[float](taskpool = tp)
    echo "\nstart"
    let res = await jobs.submit(addNums(1.0, 2.0,))

    # await sleepAsync(100.milliseconds)
    echo "result: ", res.repr

    # echo "\nRES: ", args.value

    check true

