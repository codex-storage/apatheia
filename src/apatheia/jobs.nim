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
  JobQueue*[T] = ref object
    queue*: SignalQueue[(uint, T)]
    futures*: Table[uint, Future[T]]
    taskpool*: Taskpool
    running*: bool

proc processJobs*(jobs: JobQueue) {.async.} =
  while jobs.running:
    echo "jobs running..."
    let res = get await jobs.queue.wait()
    echo "jobs result: ", res.repr
    echo "jobs futes: ", jobs.unsafeAddr.pointer.repr
    echo "jobs futes: ", jobs.futures.keys().toSeq()
    let (id, ret) = res
    let fut = jobs.futures[id]
    fut.complete(ret)

proc createFuture*[T](jobs: JobQueue[T], name: static string): (uint, Future[T]) =
  let fut = newFuture[T](name)
  jobs.futures[fut.id()] = fut
  echo "jobs added: ", jobs.unsafeAddr.pointer.repr, " => ", jobs.futures.keys().toSeq()
  return (fut.id(), fut, )

proc newJobQueue*[T](maxItems: int = 0, taskpool: Taskpool = Taskpool.new()): JobQueue[T] {.raises: [ApatheiaSignalErr].} =
  result = JobQueue[T](queue: newSignalQueue[(uint, T)](maxItems), taskpool: taskpool, running: true)
  asyncSpawn(processJobs(result))

macro submitMacro*(tp: untyped, jobs: untyped, exp: untyped): untyped =
  ## modifies the call expression to include the job queue and 
  ## the job id parameters

  let futName = genSym(nskLet, "fut")
  let idName = genSym(nskLet, "id")
  let nm = newLit(repr(exp))
  let queueExpr = quote do:
    `jobs`.queue
  var fncall = nnkCall.newTree(exp[0])
  fncall.add(queueExpr)
  fncall.add(idName)
  for p in exp[1..^1]: fncall.add(p)

  result = quote do:
    let (`idName`, `futName`) = createFuture(`jobs`, `nm`)
    `jobs`.taskpool.spawn(`fncall`)
    `futName`
  
  echo "submit: res:\n", result.repr
  echo ""

template submit*[T](jobs: JobQueue[T], exp: untyped): Future[T] =
  submitMacro(T, jobs, exp)

