import std/os
import std/sequtils

import chronos
import chronos/threadsync
import chronos/unittest2/asynctests
import taskpools

import apatheia/queues

type
  OpenArrayHolder*[T] = object
    data*: ptr UncheckedArray[T]
    size*: int
  DataObj = ref object
    holder: OpenArrayHolder[char]

template toOpenArray*[T](arr: OpenArrayHolder[T]): auto =
  system.toOpenArray(arr.data, 0, arr.size)

proc toArrayHolder*[T](data: seq[T]): OpenArrayHolder[T] =
    OpenArrayHolder[T](
      data: cast[ptr UncheckedArray[T]](unsafeAddr(data[0])), size: data.len()
    )

proc worker(data: ptr OpenArrayHolder[char], queue: SignalQueue[int]) =
  os.sleep(1_000)
  assert data[].data != nil
  echo "worker: ", data[].toOpenArray()
  discard queue.send(data[].toOpenArray().len())

proc finalizer(obj: DataObj) =
  echo "FINALIZE!!"
  obj.holder.data.dealloc()
  obj.holder.data = nil

proc runTest(tp: TaskPool, queue: SignalQueue[int]) {.async.} =
  ## init
  var obj: DataObj 
  new(obj, finalizer)
  
  obj.holder.data = cast[ptr UncheckedArray[char]](alloc0(13))
  for i, c in "hello world!":
    obj.holder.data[i] = c
  obj.holder.size = 12

  echo "spawn worker"
  tp.spawn worker(addr obj.holder, queue)

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



