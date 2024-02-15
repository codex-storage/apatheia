import std/tables
import std/macros
import std/sequtils

import ./queues

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
  JobId* = uint ## job id, should match `future.id()`

  JobQueue*[T] = ref object
    ## job queue object
    queue*: SignalQueue[(JobId, T)]
    futures*: Table[JobId, Future[T]]
    taskpool*: Taskpool
    running*: bool

  JobResult*[T] = object
    ## hold a job result to be returned by jobs
    id*: JobId
    queue*: SignalQueue[(JobId, T)]

proc processJobs*[T](jobs: JobQueue[T]) {.async.} =
  ## Starts a "detached" async processor for a given job queue.
  ## 
  ## This processor waits for events from the queue in the JobQueue
  ## and complete the associated futures.

  const tn: string = $(JobQueue[T])
  info "Processing jobs in job queue for type ", type=tn
  while jobs.running:
    let res = await(jobs.queue.wait()).get()
    trace "got job result", jobResult = $res
    let (id, ret) = res
    var fut: Future[T]
    if jobs.futures.pop(id, fut):
      fut.complete(ret)
    else:
      raise newException(IndexDefect, "missing future: " & $id)
  info "Processing jobs in job queue"

proc createFuture*[T](jobs: JobQueue[T], name: static string): (JobResult[T], Future[T]) =
  let fut = newFuture[T](name)
  let id = JobId fut.id()
  jobs.futures[id] = fut
  echo "jobs added: ", jobs.futures.unsafeAddr.pointer.repr, " => ", jobs.futures.keys().toSeq()
  return (JobResult[T](id: id, queue: jobs.queue), fut, )

proc newJobQueue*[T](maxItems: int = 0, taskpool: Taskpool = Taskpool.new()): JobQueue[T] {.raises: [ApatheiaSignalErr].} =
  result = JobQueue[T](queue: newSignalQueue[(uint, T)](maxItems), taskpool: taskpool, running: true)
  asyncSpawn(processJobs(result))

macro submitMacro(tp: untyped, jobs: untyped, exp: untyped): untyped =
  ## modifies the call expression to include the job queue and 
  ## the job id parameters

  let jobRes = genSym(nskLet, "jobRes")
  let futName = genSym(nskLet, "fut")
  let nm = newLit(repr(exp))
  var fncall = nnkCall.newTree(exp[0])
  fncall.add(jobRes)
  for p in exp[1..^1]: fncall.add(p)

  result = quote do:
    let (`jobRes`, `futName`) = createFuture(`jobs`, `nm`)
    expandMacros:
      `jobs`.taskpool.spawn(`fncall`)
    `futName`

  echo "submit: res:\n", result.repr
  echo ""

template submit*[T](jobs: JobQueue[T], exp: untyped): Future[T] =
  submitMacro(T, jobs, exp)

