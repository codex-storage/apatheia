
import ./types

import chronos
import results
import chronos/threadsync

export types

type
  ChanPtr[T] = ptr Channel[T]

proc allocSharedChannel[T](): ChanPtr[T] =
  cast[ChanPtr[T]](allocShared0(sizeof(Channel[T])))

type
  AsyncQueue*[T] = object
    signal: ThreadSignalPtr
    chan*: ChanPtr[T]

proc new*[T](tp: typedesc[AsyncQueue[T]]): AsyncQueue[T] {.raises: [ApatheiaSignalErr].} =
  let res = ThreadSignalPtr.new()
  if res.isErr():
    raise newException(ApatheiaSignalErr, msg: res.err())
  result.signal = res.get()
  result.chan = allocSharedChannel()
  

