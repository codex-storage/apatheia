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
  SeqDataPtr*[T] = object
    data*: ptr UncheckedArray[T]
    size*: int

template toOpenArray*[T](arr: SeqDataPtr[T]): auto =
  system.toOpenArray(arr.data, 0, arr.size)

proc toSeqDataPtr*[T](data: seq[T]): SeqDataPtr[T] =
    SeqDataPtr[T](
      data: cast[ptr UncheckedArray[T]](unsafeAddr(data[0])), size: data.len()
    )

proc worker(data: SeqDataPtr[char], sig: ThreadSignalPtr) =
  os.sleep(300)
  echo "running worker: "
  echo "worker: ", data.toOpenArray()
  for i, c in data.toOpenArray():
    data.data[i] = char(c.uint8 + 10)
  discard sig.fireSync()

proc runTest(tp: TaskPool, sig: ThreadSignalPtr) {.async.} =
  ## init
  var obj = "hello world!".toSeq()

  echo "spawn worker"
  tp.spawn worker(obj.toSeqDataPtr(), sig)

  ## adding fut.wait(100.milliseconds) creates memory issue
  await wait(sig).wait(10.milliseconds)
  ## just doing the wait is fine:
  # await wait(sig)

proc runTests(tp: TaskPool, sig: ThreadSignalPtr) {.async.} =
  for i in 1..10_000:
    try:
      await runTest(tp, sig)
      os.sleep(200)
    except AsyncTimeoutError:
      echo "looping..."
      GC_fullCollect()

suite "async tests":
  var tp = Taskpool.new(num_threads = 2) # Default to the number of hardware threads.
  let sig = ThreadSignalPtr.new().get()

  asyncTest "test":
    await runTests(tp, sig)
