import std/os
import std/sequtils

import chronos
import chronos/threadsync
import chronos/unittest2/asynctests
import taskpools

import apatheia/queues

proc worker(data: seq[char], queue: SignalQueue[int]) =
  os.sleep(50)
  echo "worker: ", data
  discard queue.send(data.len())

suite "async tests":

  var tp = Taskpool.new(num_threads = 2) # Default to the number of hardware threads.
  var queue = newSignalQueue[int]()

  asyncTest "test":

    ## init
    var data = "hello world!".toSeq
    tp.spawn worker(data, queue)

    let res = await wait(queue)
    check res.get() == 12


