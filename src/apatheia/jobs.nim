import std/tables
import std/macros

import ./queues
import ./memholders

import taskpools
import chronos
import chronicles

export queues
export chronicles

logScope:
  # Lexical properties are typically assigned to a constant:
  topics = "apatheia jobs"

## This module provides a simple way to submit jobs to taskpools
## and getting a result returned via an async future.
## 
##

type
  JobQueue*[T] = ref object ## job queue object
    queue*: SignalQueue[(JobId, T)]
    futures*: Table[JobId, Future[T]]
    taskpool*: Taskpool
    running*: bool

  JobResult*[T] = object ## hold a job result to be returned by jobs
    id*: JobId
    queue*: SignalQueue[(JobId, T)]

  OpenArrayHolder*[T] = object
    data*: ptr UncheckedArray[T]
    size*: int

template toOpenArray*[T](arr: OpenArrayHolder[T]): auto =
  system.toOpenArray(arr.data, 0, arr.size)

func jobId*[T](fut: Future[T]): JobId =
  JobId fut.id()

proc processJobs*[T](jobs: JobQueue[T]) {.async.} =
  ## Starts a "detached" async processor for a given job queue.
  ## 
  ## This processor waits for events from the queue in the JobQueue
  ## and complete the associated futures.

  const tn: string = $(JobQueue[T])
  info "Processing jobs in job queue for type ", type = tn
  while jobs.running:
    let res = await(jobs.queue.wait()).get()
    trace "got job result", jobResult = $res
    let (id, ret) = res
    releaseMemory(id) # release any retained memory
    var fut: Future[T]
    if jobs.futures.pop(id, fut):
      fut.complete(ret)
    else:
      raise newException(IndexDefect, "missing future: " & $id)
  info "Finishing processing jobs for type ", type = tn

proc createFuture*[T](jobs: JobQueue[T], name: static string): (JobResult[T], Future[T]) =
  ## Creates a future that returns the result of the associated job.
  let fut = newFuture[T](name)
  let id = fut.jobId()
  jobs.futures[id] = fut
  trace "jobs added: ", numberJobs = jobs.futures.len()
  return (JobResult[T](id: id, queue: jobs.queue), fut)

proc newJobQueue*[T](
    maxItems: int = 0, taskpool: Taskpool = Taskpool.new()
): JobQueue[T] {.raises: [ApatheiaSignalErr].} =
  ## Creates a new async-compatible threaded job queue.
  result = JobQueue[T](
    queue: newSignalQueue[(uint, T)](maxItems), taskpool: taskpool, running: true
  )
  asyncSpawn(processJobs(result))

template checkJobArgs*[T](exp: seq[T], fut: untyped): OpenArrayHolder[T] =
  when T is byte | SomeInteger | SomeFloat:
    let rval = SeqHolder[T](data: exp)
    fut.jobId().retainMemory(rval)
    let expPtr = OpenArrayHolder[T](
      data: cast[ptr UncheckedArray[T]](unsafeAddr(rval.data[0])), size: rval.data.len()
    )
    expPtr
  else:
    {.error: "unsupported sequence type for job argument: " & $typeof(seq[T]).}

template checkJobArgs*(exp: typed, fut: untyped): auto =
  exp

macro submitMacro(tp: untyped, jobs: untyped, exp: untyped): untyped =
  ## modifies the call expression to include the job queue and 
  ## the job id parameters

  let jobRes = ident("jobRes")
  let futName = ident("fut")
  let nm = newLit(repr(exp))

  var argids = newSeq[NimNode]()
  var letargs = nnkLetSection.newTree()
  for i, p in exp[1 ..^ 1]:
    echo "CHECK ARGS: ", p.treeRepr
    let id = ident "arg" & $i
    argids.add(id)
    let pn = nnkCall.newTree(ident"checkJobArgs", p, `futName`)
    letargs.add nnkIdentDefs.newTree(id, newEmptyNode(), pn)
    # fncall.add(nnkCall.newTree(ident"checkJobArgs", p, `futName`))
  echo "\nSUBMIT: ARGS: LET:\n", letargs.repr
  echo ""

  var fncall = nnkCall.newTree(exp[0])
  fncall.add(jobRes)
  for p in argids:
    fncall.add(p)

  result = quote:
    block:
      let (`jobRes`, `futName`) = createFuture(`jobs`, `nm`)
      `letargs`
      when typeof(`fncall`) isnot void:
        {.
          error:
            "Apatheia jobs cannot return values. The given proc returns type: " &
            $(typeof(`fncall`)) & " for call " & astToStr(`fncall`)
        .}
      `jobs`.taskpool.spawn(`fncall`)
      `futName`

  when isMainModule:
    echo "\nSUBMIT MACRO::\n", result.repr
    echo ""

template submit*[T](jobs: JobQueue[T], exp: untyped): Future[T] =
  submitMacro(T, jobs, exp)

when isMainModule:
  import os
  import chronos/threadsync
  import chronos/unittest2/asynctests
  import std/macros

  proc addNumValues(
      jobResult: JobResult[float], base: float, vals: OpenArrayHolder[float]
  ) =
    os.sleep(100)
    var res = base
    for x in vals.toOpenArray():
      res += x
    discard jobResult.queue.send((jobResult.id, res))

  proc addStrings(jobResult: JobResult[float], vals: OpenArrayHolder[string]) =
    discard

  suite "async tests":
    var tp = Taskpool.new(num_threads = 2) # Default to the number of hardware threads.

    asyncTest "basic openarray":
      var jobs = newJobQueue[float](taskpool = tp)

      let job = jobs.submit(addNumValues(10.0, @[1.0.float, 2.0]))
      let res = await job

      check res == 13.0

    asyncTest "don't compile":
      check not compiles(
        block:
          var jobs = newJobQueue[float](taskpool = tp)
          let job = jobs.submit(addStrings(@["a", "b", "c"]))
      )
