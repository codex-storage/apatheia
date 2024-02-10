import std/options
import ./types

import chronos
import results
import chronos/threadsync

export types
export options

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

proc send*[T](c: AsyncQueue[T], msg: sink T) {.inline.} =
  ## Sends a message to a thread. `msg` is copied.
  c.chan.send(msg)

proc trySend*[T](c: AsyncQueue[T], msg: sink T): bool {.inline.} =
  c.chan.trySend(msg)

proc recv*[T](c: AsyncQueue[T]): T =
  c.chan.recv()

proc tryRecv*[T](c: AsyncQueue[T]): Option[T] =
  let res = c.chan.recv()
  if res.dataAvailable:
    some res.msg

