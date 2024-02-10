import std/channels

import ./types

import chronos
import results
import chronos/threadsync

export types

type

  AsyncQueue*[T] = object
    signal: ThreadSignalPtr
    chan*: T

proc new*[T](tp: typedesc[AsyncQueue[T]]): AsyncQueue[T] {.raises: [ApatheiaSignalErr].} =
  let res = ThreadSignalPtr.new()
  if res.isErr():
    raise newException(ApatheiaSignalErr, msg: res.err())
  else:
    result.signal = res.get()

