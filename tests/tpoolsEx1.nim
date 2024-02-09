
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

when false:
  let fut = newFlowVar(typeof(float))
  proc taskpool_term(k: openArray[float]; fut: Flowvar[float]) {.nimcall.} =
    let res = term(k)
    readyWith(fut, res)

  let taskNode = new(TaskNode, workerContext.currentTask) do:
    type
      ScratchObj_486539473 = object
        k: seq[float]
        fut: Flowvar[float]

    let scratch_486539466 = cast[ptr ScratchObj_486539473](c_calloc(csize_t(1), csize_t(16)))
    if isNil(scratch_486539466):
      raise (ref OutOfMemDefect)(msg: "Could not allocate memory", parent: nil)
    block:
      var isoTemp_486539469 = isolate(`@`(args))
      scratch_486539466.k = extract(isoTemp_486539469)
      var isoTemp_486539471 = isolate(fut)
      scratch_486539466.fut = extract(isoTemp_486539471)

    proc taskpool_term_486539474(args: pointer) {.gcsafe, nimcall, raises: [].} =
      let objTemp_486539468 = cast[ptr ScratchObj_486539473](args)
      let k_486539470 = objTemp_486539468.k
      let fut_486539472 = objTemp_486539468.fut
      taskpool_term(k_486539470, fut_486539472)

    proc destroyScratch_486539475(args: pointer) {.gcsafe, nimcall,
        raises: [].} =
      let obj_486539476 = cast[ptr ScratchObj_486539473](args)
      `=destroy`(obj_486539476[])

    Task(callback: taskpool_term_486539474,
         args: scratch_486539466,
         destroy: destroyScratch_486539475)

  schedule(workerContext, taskNode)