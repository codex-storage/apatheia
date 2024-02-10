import std/os

import chronos
import chronos/threadsync
import chronos/unittest2/asynctests
import taskpools

import apatheia/queues

## todo: setup basic async + threadsignal + taskpools example here
## 

type
  ThreadArg = object
    doneSig: ThreadSignalPtr
    value: float

proc addNums(a, b: float, queue: SignalQueue[float]) =
  os.sleep(500)
  discard queue.send(a + b)

suite "async tests":

  var tp = Taskpool.new(num_threads = 2) # Default to the number of hardware threads.
  var queue = newSignalQueue[float]()

  asyncTest "test":

    tp.spawn addNums(1.0, 2.0, queue)

    # await sleepAsync(100.milliseconds)
    await wait(queue).wait(1500.milliseconds)

    # echo "\nRES: ", args.value

    check true

