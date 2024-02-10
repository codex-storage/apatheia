import ./queues

import taskpools

export queues

type
  JobQueue*[T] = object
    queue*: SignalQueue[T]
    taskpool*: Taskpool

proc newJobQueue*[T](maxItems: int = 0, taskpool: Taskpool = Taskpool.new()): JobQueue[T] {.raises: [ApatheiaSignalErr].} =
  JobQueue[T](queue: newSignalQueue[T](maxItems), taskpool: taskpool)

template awaitJob*[T](jobs: JobQueue[T], exp: typed): auto =
  jobs.taskpool.spawn(exp)
  await wait(jobs.queue)
