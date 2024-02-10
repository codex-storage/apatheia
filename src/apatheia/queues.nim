import ./types

import chronos
import results
import chronos/threadsync

export types

type

  AsyncQueue*[T] = object
    signal: ThreadSignalPtr
    item*: T

proc new*[T](tp: typedesc[AsyncQueue[T]]): AsyncQueue[T] {.raises: [ApatheiaException].} =
  let res = ThreadSignalPtr.new()
  if res.isErr():
    raise newException(ApatheiaException, msg: res.err())


