import std/os
import chronos
import chronos/threadsync
import chronos/unittest2/asynctests
import taskpools

## This example mocks up a sequence and uses
## a finalizer and GC_fullCollect to more
## deterministically create a memory error.
## 
## see `exFailureSeq.nim` for a probablisitc based
## example using a real seq object.
## 

type
  Seq*[T] = object
    data*: ptr UncheckedArray[T]
    size*: int

  DataObj = ref object
    mockSeq: Seq[char]

template toOpenArray*[T](arr: Seq[T]): auto =
  system.toOpenArray(arr.data, 0, arr.size)

proc worker(data: ptr Seq[char], sig: ThreadSignalPtr) =
  os.sleep(5_000)
  echo "running worker: "
  assert data[].data != nil
  echo "worker: ", data[].toOpenArray()
  discard sig.fireSync()

proc finalizer(obj: DataObj) =
  echo "finalize DataObj and freeing mockSeq"
  obj.mockSeq.data.dealloc()
  obj.mockSeq.data = nil

proc initMockSeq(msg: string): Seq[char] =
  result.data = cast[ptr UncheckedArray[char]](alloc0(13))
  for i, c in msg:
    result.data[i] = c
  result.size = 12

proc runTest(tp: TaskPool, sig: ThreadSignalPtr) {.async.} =
  ## init
  var obj: DataObj
  obj.new(finalizer)
  obj.mockSeq = initMockSeq("hello world!")

  echo "spawn worker"
  tp.spawn worker(addr obj.mockSeq, sig)

  ## adding fut.wait(100.milliseconds) creates memory issue
  try:
    await wait(sig)
    echo "runTest got sig"
  finally:
    echo "runTest done"
  ## just doing the wait is fine:
  # await wait(sig)

proc doFail() {.async.} =
  await sleepAsync(10.milliseconds)
  raise newException(CatchableError, "error")

suite "async tests":
  var tp = Taskpool.new(num_threads = 2) # Default to the number of hardware threads.
  let sig = ThreadSignalPtr.new().get()

  asyncTest "test":
    try:
      await allFutures(
        runTest(tp, sig),
        doFail(),
      )
    except Defect:
      echo "Errored out"
    finally:
      echo "Run GC"
      GC_fullCollect()
      os.sleep(2_000)
