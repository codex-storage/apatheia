import std/os
import std/sequtils
import chronos
import chronos/threadsync
import chronos/unittest2/asynctests
import taskpools

## create a probablistically likely failure of 
## using sequence memory from another thread
## with refc. 
## 
## However, unlike `exFailure.nim`, this can take
## a while to run.
## 
## It may not always produce an error either, but
## generally does so in a few seconds of running.
## 

proc worker(data: ptr seq[seq[char]], sig: ThreadSignalPtr) =
  # os.sleep(100)
  echo "running worker: "
  echo "worker: ", data.pointer.repr
  echo "worker: ", data[]
  # for i, d in data:
  #   for j, c in d:
  #     data[i][j] = char(c.uint8 + 10)
  GC_fullCollect()
  discard sig.fireSync()

proc runTest(tp: TaskPool, sig: ThreadSignalPtr, i: int) {.async.} =
  ## init
  # await sleepAsync(10.milliseconds)
  var obj1 = ("hello world! " & $i).toSeq()
  var obj2 = "goodbye denver!".toSeq()
  var data = @[obj1, obj2]

  # echo "spawn worker"
  tp.spawn worker(addr data, sig)

  await wait(sig)
  echo "data: ", data.addr.pointer.repr
  echo "data: ", data
  echo ""

proc runTests(tp: TaskPool, sig: ThreadSignalPtr) {.async.} =
  var futs = newSeq[Future[void]]()
  for i in 1..1:
    let f = runTest(tp, sig, i)
    # futs.add f
    await f
    GC_fullCollect()
  await allFutures(futs)

suite "async tests":
  var tp = Taskpool.new(num_threads = 4) # Default to the number of hardware threads.
  let sig = ThreadSignalPtr.new().get()

  asyncTest "test":
    await runTests(tp, sig)
    # os.sleep(10_000)
