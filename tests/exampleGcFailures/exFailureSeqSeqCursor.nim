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

type
  SeqCursor* = object
    data* {.cursor.}: seq[seq[char]]

proc worker(data: SeqCursor, sig: ThreadSignalPtr) =
  os.sleep(10)
  echo "running worker: "
  echo "worker: ", data.data
  # for i, d in data.data:
  #   for j, c in d:
  #     data.data[i][j] = char(c.uint8 + 10)
  discard sig.fireSync()

proc runTest(tp: TaskPool, sig: ThreadSignalPtr) {.async.} =
  ## init
  var obj1 = "hello world!".toSeq()
  var obj2 = "goodbye denver!".toSeq()
  var data = @[obj1, obj2]
  var cur = SeqCursor(data: data)

  # echo "spawn worker"
  tp.spawn worker(cur, sig)

  ## adding fut.wait(100.milliseconds) creates memory issue
  await wait(sig)
  ## just doing the wait is fine:
  # await wait(sig)

proc runTests(tp: TaskPool, sig: ThreadSignalPtr) {.async.} =
  for i in 1..3_000:
    try:
      await runTest(tp, sig)
    except AsyncTimeoutError:
      # os.sleep(1)
      # echo "looping..."
      # GC_fullCollect()
      discard

suite "async tests":
  var tp = Taskpool.new(num_threads = 2) # Default to the number of hardware threads.
  let sig = ThreadSignalPtr.new().get()

  asyncTest "test":
    await runTests(tp, sig)
    os.sleep(10_000)
