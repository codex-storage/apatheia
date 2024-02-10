import std/os

import chronos
import chronos/threadsync
import chronos/unittest2/asynctests
import taskpools

import apatheia/queues
import apatheia/jobs

## todo: setup basic async + threadsignal + taskpools example here
## 

proc addNums(a, b: float): float =
  os.sleep(500)
  echo "adding: ", a, " + ", b
  return a + b

proc addNums(queue: SignalQueue[float], a, b: float) =
  let res = addNums(a, b)
  discard queue.send(res)

suite "async tests":

  # var tp = Taskpool.new(num_threads = 2) # Default to the number of hardware threads.
  # var queue = newSignalQueue[float]()
  var jobs = newJobQueue[float]()

  asyncTest "test":

    echo "\nstart"
    let res = jobs.awaitSpawn addNums(jobs.queue, 1.0, 2.0)

    # await sleepAsync(100.milliseconds)
    echo "result: ", res.repr

    # echo "\nRES: ", args.value

    check true

