import std/os
import std/sequtils

import chronos
import chronos/threadsync
import chronos/unittest2/asynctests
import taskpools

import apatheia/queues

type
  Seq*[T] = object
    data*: ptr UncheckedArray[T]
    size*: int

  DataObj = ref object
    mockSeq: Seq[char]

template toOpenArray*[T](arr: Seq[T]): auto =
  system.toOpenArray(arr.data, 0, arr.size)

proc worker(data: ptr Seq[char], queue: SignalQueue[int]) =
  os.sleep(1_000)
  echo "running worker: "
  assert data[].data != nil
  echo "worker: ", data[].toOpenArray()
  discard queue.send(data[].toOpenArray().len())

proc finalizer(obj: DataObj) =
  echo "FINALIZE!!"
  obj.mockSeq.data.dealloc()
  obj.mockSeq.data = nil

proc initMockSeq(msg: string): Seq[char] =
  result.data = cast[ptr UncheckedArray[char]](alloc0(13))
  for i, c in msg:
    result.data[i] = c
  result.size = 12

proc runTest(tp: TaskPool, queue: SignalQueue[int]) {.async.} =
  ## init
  var obj: DataObj
  new(obj, finalizer)
  
  obj.mockSeq = initMockSeq("hello world!")

  echo "spawn worker"
  tp.spawn worker(addr obj.mockSeq, queue)

  let res =
    await wait(queue).wait(100.milliseconds)
  check res.get() == 12

suite "async tests":

  var tp = Taskpool.new(num_threads = 2) # Default to the number of hardware threads.
  var queue = newSignalQueue[int]()

  asyncTest "test":

    try:
      await runTest(tp, queue)
    except AsyncTimeoutError:
      echo "Run GC"
      GC_fullCollect()
      os.sleep(2_000)
      echo "Done"



