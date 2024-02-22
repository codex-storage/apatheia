import std/os
import std/sequtils
import chronos
import chronos/threadsync
import chronos/unittest2/asynctests
import taskpools

type
  Seq*[T] = object
    data*: ptr UncheckedArray[T]
    size*: int


template toOpenArray*[T](arr: Seq[T]): auto =
  system.toOpenArray(arr.data, 0, arr.size)

proc toArrayHolder*[T](data: seq[T]): Seq[T] =
    Seq[T](
      data: cast[ptr UncheckedArray[T]](unsafeAddr(data[0])), size: data.len()
    )

proc worker(data: Seq[char], sig: ThreadSignalPtr) =
  os.sleep(100)
  echo "running worker: "
  echo "worker: ", data.toOpenArray()
  for i, c in data.toOpenArray():
    data.data[i] = char(c.uint8 + 10)
  discard sig.fireSync()

proc runTest(tp: TaskPool, sig: ThreadSignalPtr) {.async.} =
  ## init
  var obj = "hello world!".toSeq()

  echo "spawn worker"
  tp.spawn worker(obj.toArrayHolder(), sig)

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
