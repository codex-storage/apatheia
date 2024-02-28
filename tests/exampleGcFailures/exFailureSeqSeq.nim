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

proc worker(data: seq[seq[char]], sig: ThreadSignalPtr) =
  os.sleep(100)
  echo "running worker: "
  echo "worker: ", data
  # for i, d in data:
  #   for j, c in d:
  #     d[j] = char(c.uint8 + 10)
  GC_fullCollect()
  discard sig.fireSync()

proc runTest(tp: TaskPool, sig: ThreadSignalPtr) {.async.} =
  ## init
  var obj1 = "hello world!".toSeq()
  var obj2 = "goodbye denver!".toSeq()
  var data = @[obj1, obj2]

  # echo "spawn worker"
  tp.spawn worker(data, sig)

  # await wait(sig)
  echo "data: ", data

proc runTests(tp: TaskPool, sig: ThreadSignalPtr) {.async.} =
  for i in 1..10_000:
    try:
      await runTest(tp, sig)
    except AsyncTimeoutError:
      # os.sleep(1)
      # echo "looping..."
      discard
    GC_fullCollect()

suite "async tests":
  var tp = Taskpool.new(num_threads = 8) # Default to the number of hardware threads.
  let sig = ThreadSignalPtr.new().get()

  asyncTest "test":
    await runTests(tp, sig)
    # os.sleep(10_000)
