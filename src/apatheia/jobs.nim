import ./queues

import taskpools

export queues

## TODO:
## setup queue to tie together future and result for a specific instance
## this setup will result in out-of-order results
##

type
  JobQueue*[T] = object
    queue*: SignalQueue[T]
    taskpool*: Taskpool

proc newJobQueue*[T](maxItems: int = 0, taskpool: Taskpool = Taskpool.new()): JobQueue[T] {.raises: [ApatheiaSignalErr].} =
  JobQueue[T](queue: newSignalQueue[T](maxItems), taskpool: taskpool)

template submit*[T](jobs: JobQueue[T], exp: typed): Future[T] =
  jobs.taskpool.spawn(exp)
  await wait(jobs.queue)
