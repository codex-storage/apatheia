import std/os

import chronos
import chronos/threadsync
import chronos/unittest2/asynctests
import taskpools

## todo: setup basic async + threadsignal + taskpools example here
## 

type
  ThreadArg = object
    startSig: ThreadSignalPtr
    doneSig: ThreadSignalPtr
    value: float

proc addNums(a, b: float, ret: ptr ThreadArg) =
  ret.value = a + b
  os.sleep(500)
  let res = ret.doneSig.fireSync().get()
  if not res:
    echo "ERROR FIRING!"

suite "async tests":

  var tp = Taskpool.new(num_threads = 2) # Default to the number of hardware threads.

  asyncTest "test":
    var args = ThreadArg()
    args.startSig = ThreadSignalPtr.new().get()
    args.doneSig = ThreadSignalPtr.new().get()

    tp.spawn addNums(1, 2, addr args)
    # await sleepAsync(100.milliseconds)
    await wait(args.doneSig).wait(1500.milliseconds)

    echo "\nRES: ", args.value

    check true

