
import std/[strutils, math, cpuinfo]

import taskpools

# From https://github.com/nim-lang/Nim/blob/v1.6.2/tests/parallel/tpi.nim
# Leibniz Formula https://en.wikipedia.org/wiki/Leibniz_formula_for_%CF%80
proc term(k: openArray[float]): float =
  for n in k:
    result += n

proc piApprox(tp: Taskpool, n: int): float =
  var args = newSeq[float]()
  for i in 0..n:
    args[i] = i.toFloat()
  result = tp.spawn term(args) # Schedule a task on the threadpool a return a handle to retrieve the result.

proc main() =
  var n = 10_000
  var nthreads = countProcessors()

  var tp = Taskpool.new(num_threads = nthreads) # Default to the number of hardware threads.

  echo tp.piApprox(n)

  tp.syncAll()                                  # Block until all pending tasks are processed (implied in tp.shutdown())
  tp.shutdown()

# Compile with nim c -r -d:release --threads:on --outdir:build example.nim
main()