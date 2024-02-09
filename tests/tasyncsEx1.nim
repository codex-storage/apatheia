
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

proc addNums(a, b: float, ret: ptr float) =
  ret[] = a + b

suite "async tests":

  var tp = Taskpool.new(num_threads = 2) # Default to the number of hardware threads.

  asyncTest "test":
    var args = ThreadArg()
    args.startSig = ThreadSignalPtr.new().get()
    args.doneSig = ThreadSignalPtr.new().get()

    tp.spawn addNums(1, 2, addr args.value)
    await sleepAsync(100.milliseconds)
    echo "\nRES: ", args.value

    check true

