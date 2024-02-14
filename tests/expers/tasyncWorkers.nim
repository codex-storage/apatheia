import std/os

import chronos
import chronos/threadsync
import chronos/unittest2/asynctests
import taskpools

## todo: setup basic async + threadsignal + taskpools example here
## 

var todo: Future[float]

proc completeAfter() {.async.} =
  {.cast(gcsafe).}:
    await sleepAsync(500.milliseconds)
    echo "completing result: "
    todo.complete(4.0)

proc addNums(a, b: float): Future[float] =
  {.cast(gcsafe).}:
    let fut = newFuture[float]("addNums")
    todo = fut
    result = fut

suite "async tests":

  # var tp = Taskpool.new(num_threads = 2) # Default to the number of hardware threads.

  asyncTest "test":

    # await sleepAsync(100.milliseconds)
    let fut = addNums(1, 3)
    asyncSpawn completeAfter()
    echo "\nawaiting result: "
    let res = await fut

    echo "\nRES: ", res

    check true

