import std/os
import chronos
import chronos/threadsync
import chronos/unittest2/asynctests
import taskpools

type
  Test* = object
    count*: int

proc `=destroy`*(obj: var Test) =
  echo "destroy count: ", obj.count, " thread: ", getThreadId()

proc worker(data: seq[Test], sig: ThreadSignalPtr) =
  os.sleep(40)
  echo "running worker: ", getThreadId()
  echo "worker: ", data
  discard sig.fireSync()

proc runTest(tp: TaskPool, sig: ThreadSignalPtr) {.async.} =
  ## init
  var obj = @[Test(count: 1), Test(count: 2)]

  echo "spawn worker"
  tp.spawn worker(obj, sig)

  obj[0].count = 10
  obj[1].count = 20
  ## adding fut.wait(100.milliseconds) creates memory issue
  await wait(sig)
  ## just doing the wait is fine:
  # await wait(sig)

proc runTests(tp: TaskPool, sig: ThreadSignalPtr) {.async.} =
  for i in 1..1:
    try:
      echo "\n\nrunning main: ", getThreadId()
      await runTest(tp, sig)
      os.sleep(200)
    except AsyncTimeoutError:
      echo "looping..."

suite "async tests":
  var tp = Taskpool.new(num_threads = 2) # Default to the number of hardware threads.
  let sig = ThreadSignalPtr.new().get()

  asyncTest "test":
    await runTests(tp, sig)
