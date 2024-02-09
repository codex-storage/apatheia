
import chronos
import chronos/threadsync
import taskpools

## todo: setup basic example here
## 

proc test() =
  let signal = ThreadSignalPtr.new().tryGet()

