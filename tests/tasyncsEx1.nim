
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
    value: int

suite "async tests":

  asyncTest "test":
    await sleepAsync(100.milliseconds)
    check true

