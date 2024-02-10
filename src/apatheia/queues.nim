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
  SignalQueue*[T] = object
    signal: ThreadSignalPtr
    chan*: ChanPtr[T]

proc newSignalQueue*[T](): SignalQueue[T] {.raises: [ApatheiaSignalErr].} =
  let res = ThreadSignalPtr.new()
  if res.isErr():
    raise newException(ApatheiaSignalErr, msg: res.err())
  result.signal = res.get()
  result.chan = allocSharedChannel()

proc send*[T](c: SignalQueue[T], msg: sink T) {.inline.} =
  ## Sends a message to a thread. `msg` is copied.
  c.chan.send(msg)
  c.signal.fireSync()

proc trySend*[T](c: SignalQueue[T], msg: sink T): bool {.inline.} =
  result = c.chan.trySend(msg)
  if result:
    c.signal.fireSync()

proc recv*[T](c: SignalQueue[T]): T =
  c.chan.recv()

proc tryRecv*[T](c: SignalQueue[T]): Option[T] =
  let res = c.chan.recv()
  if res.dataAvailable:
    some res.msg

