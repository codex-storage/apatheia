import std/os
import std/sequtils

import chronos
import chronos/threadsync
import chronos/unittest2/asynctests
import taskpools

import apatheia/queues

type
  DataObj = ref object
    data: seq[char]

proc worker(data: OpenArrayHolder[char], queue: SignalQueue[int]) =
  os.sleep(1_000)
  echo "worker: ", data
  discard queue.send(data.len())

proc finalizer(obj: DataObj) =
  echo "FINALIZE!!"

proc runTest(tp: TaskPool, queue: SignalQueue[int]) {.async.} =
  ## init
  var obj: DataObj 
  new(obj, finalizer)
  obj.data = "hello world!".toSeq

  echo "spawn worker"
  tp.spawn worker(obj.data, queue)

  let res =
    await wait(queue).wait(100.milliseconds)
  check res.get() == 12

suite "async tests":

  var tp = Taskpool.new(num_threads = 2) # Default to the number of hardware threads.
  var queue = newSignalQueue[int]()

  asyncTest "test":

    try:
      await runTest(tp, queue)
    except AsyncTimeoutError as err:
      echo "Run GC"
      GC_fullCollect()
      os.sleep(2_000)
      echo "Done"



