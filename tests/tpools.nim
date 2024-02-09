
import std/[strutils, math, cpuinfo]

import taskpools

# From https://github.com/nim-lang/Nim/blob/v1.6.2/tests/parallel/tpi.nim
# Leibniz Formula https://en.wikipedia.org/wiki/Leibniz_formula_for_%CF%80
proc term(k: int): float =
  if k mod 2 == 1:
    -4'f / float(2*k + 1)
  else:
    4'f / float(2*k + 1)

proc piApprox(tp: Taskpool, n: int): float =
  var pendingFuts = newSeq[FlowVar[float]](n)
  for k in 0 ..< pendingFuts.len:
    pendingFuts[k] = tp.spawn term(k) # Schedule a task on the threadpool a return a handle to retrieve the result.
  for k in 0 ..< pendingFuts.len:
    result += sync pendingFuts[k]     # Block until the result is available.

proc main() =
  var n = 1_000
  var nthreads = countProcessors()

  var tp = Taskpool.new(num_threads = nthreads) # Default to the number of hardware threads.

  echo formatFloat(tp.piApprox(n))

  tp.syncAll()                                  # Block until all pending tasks are processed (implied in tp.shutdown())
  tp.shutdown()

# Compile with nim c -r -d:release --threads:on --outdir:build example.nim
main()

when false:
  type
    ScratchObj_486539477 = object
      k: int
      fut: Flowvar[float]

  let scratch_486539455 = cast[ptr ScratchObj_486539477](c_calloc(csize_t 1,
      csize_t sizeof(ScratchObj_486539477)))
  if scratch_486539455.isNil:
    raise newException(OutOfMemDefect, "Could not allocate memory")
  block:
    var isoTemp_486539473 = isolate(k)
    scratch_486539455.k = extract(isoTemp_486539473)
    var isoTemp_486539475 = isolate(fut)
    scratch_486539455.fut = extract(isoTemp_486539475)
  proc taskpool_term_486539478(args`gensym15: pointer) {.gcsafe, nimcall,
      raises: [].} =
    let objTemp_486539472 = cast[ptr ScratchObj_486539477](args`gensym15)
    let k_486539474 = objTemp_486539472.k
    let fut_486539476 = objTemp_486539472.fut
    taskpool_term(k = k_486539474, fut = fut_486539476)

  proc destroyScratch_486539479(args`gensym15: pointer) {.gcsafe, nimcall,
      raises: [].} =
    let obj_486539480 = cast[ptr ScratchObj_486539477](args`gensym15)
    `=destroy`(obj_486539480[])

  Task(callback: taskpool_term_486539478, args: scratch_486539455,
      destroy: destroyScratch_486539479)