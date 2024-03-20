import std/os
import chronos
import chronos/threadsync
import chronos/unittest2/asynctests
import taskpools

type
  Seq*[T] = object
    data*: ptr UncheckedArray[T]
    size*: int

  DataObj = ref object
    mockSeq: Seq[char]

proc worker(data: seq[char], sig: ThreadSignalPtr) =
  os.sleep(4_000)
  echo "running worker: "
  echo "worker: ", data
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
  var obj = @"hello world!"

  echo "spawn worker"
  tp.spawn worker(obj, sig)

  ## adding fut.wait(100.milliseconds) creates memory issue
  await wait(sig).wait(100.milliseconds)
  ## just doing the wait is fine:
  # await wait(sig)

proc runTests(tp: TaskPool, sig: ThreadSignalPtr) {.async.} =
  for i in 1..2_000:
    try:
      await runTest(tp, sig)
      os.sleep(200)
    except AsyncTimeoutError:
      echo "looping..."

suite "async tests":
  var tp = Taskpool.new(num_threads = 2) # Default to the number of hardware threads.
  let sig = ThreadSignalPtr.new().get()

  asyncTest "test":
    await runTests(tp, sig)
