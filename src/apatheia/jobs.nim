import std/tables
import std/macros
import std/sequtils

import ./queues

import taskpools
import chronos

export queues

## TODO:
## setup queue to tie together future and result for a specific instance
## this setup will result in out-of-order results
##

type
  JobId* = uint ## job id, should match `future.id()`

  JobQueue*[T] = ref object
    queue*: SignalQueue[(JobId, T)]
    futures*: Table[JobId, Future[T]]
    taskpool*: Taskpool
    running*: bool

  JobResult*[T] = object
    id*: JobId
    queue*: SignalQueue[(JobId, T)]

proc processJobs*(jobs: JobQueue) {.async.} =
  while jobs.running:
    echo "jobs running..."
    let res = await(jobs.queue.wait()).get()
    echo "jobs result: ", res.repr
    echo "jobs futes: ", jobs.futures.unsafeAddr.pointer.repr, " => ", jobs.futures.keys().toSeq()
    let (id, ret) = res
    let fut = jobs.futures[id]
    fut.complete(ret)

proc createFuture*[T](jobs: JobQueue[T], name: static string): (JobResult[T], Future[T]) =
  let fut = newFuture[T](name)
  let id = JobId fut.id()
  jobs.futures[id] = fut
  echo "jobs added: ", jobs.futures.unsafeAddr.pointer.repr, " => ", jobs.futures.keys().toSeq()
  return (JobResult[T](id: id, queue: jobs.queue), fut, )

proc newJobQueue*[T](maxItems: int = 0, taskpool: Taskpool = Taskpool.new()): JobQueue[T] {.raises: [ApatheiaSignalErr].} =
  result = JobQueue[T](queue: newSignalQueue[(uint, T)](maxItems), taskpool: taskpool, running: true)
  asyncSpawn(processJobs(result))

macro submitMacro*(tp: untyped, jobs: untyped, exp: untyped): untyped =
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
    `jobs`.taskpool.spawn(`fncall`)
    `futName`
  
  echo "submit: res:\n", result.repr
  echo ""

template submit*[T](jobs: JobQueue[T], exp: untyped): Future[T] =
  submitMacro(T, jobs, exp)

template jobWrapper*(task: untyped) =
  template `task Wrapper`*(jobResult: JobResult[float], args: varargs[untyped]) =
    let res = unpackVarargs(`task`, args)
    discard jobResult.queue.send((jobResult.id, res,))

