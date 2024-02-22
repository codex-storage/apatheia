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

proc worker(data: seq[char], queue: SignalQueue[int]) =
  os.sleep(5000)
  echo "worker: ", data
  discard queue.send(data.len())

proc finalizer(obj: DataObj) =
  echo "FINALIZE!!"

proc runTest(tp: TaskPool, queue: SignalQueue[int]) {.async.} =
  ## init
  var data = "hello world!".toSeq
  var obj: DataObj 
  new(obj, finalizer)

  echo "spawn worker"
  tp.spawn worker(data, queue)

  let res = await wait(queue)
  check res.get() == 12

suite "async tests":

  var tp = Taskpool.new(num_threads = 2) # Default to the number of hardware threads.
  var queue = newSignalQueue[int]()

  asyncTest "test":

    await runTest(tp, queue)
    GC_fullCollect()



