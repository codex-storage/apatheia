
# Apatheia

> *Apatheia* (*Greek: ἀπάθεια; from a- "without" and pathos "suffering" or "passion"*), in Stoicism, refers to a state of mind in which one is not disturbed by the passions. It might better be translated by the word equanimity than the word indifference. 

The goal of the apatheia library is to provide a painless, suffering free multi-threading compatible with async. 

The main modules are:
- queues - queues with support for async signals
- jobs - macro and utilities for submitting jobs to a taskpool
- tasks - convenience wrapper to turn a proc into a job with a simple API

Example usage:

```nim
import taskpools
import apatheia/tasks

proc addNums(a, b: float): float {.asyncTask.} =
  os.sleep(50)
  return a + b

proc addNumValues(vals: openArray[float]): float {.asyncTask.} =
  os.sleep(100)
  result = 0.0
  for x in vals:
    result += x

suite "async tests":
  var tp = Taskpool.new(num_threads = 2) # Default to the number of hardware threads.

  asyncTest "test addNums":
    var jobs = newJobQueue[float](taskpool = tp)
    let res = await jobs.submit(addNums(1.0, 2.0,))
    check res == 3.0

  asyncTest "test addNumValues":
    var jobs = newJobQueue[float](taskpool = tp)
    let args = @[1.0, 2.0, 3.0]
    let res = await jobs.submit(addNumValues(args))
    check res == 6.0
```

Future Goals:

- support orc and refc
  + refc may require extra copying for data
- use event queues (e.g. channels) to/from thread pool 
  + make it easy to monitor and debug queue capacity
  + only use minimal AsyncFD handles
  + lessen pressure on the main chronos futures pending queue
- support backpressure at futures level
- benchmarking overhead
- special support for seq[byte]'s and strings with zero-copy
  + implement special but limited support zero-copy arguments on refc

