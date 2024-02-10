import std/options
import ./types

import results
import chronos
import results
import chronos/threadsync

export types
export options
export threadsync
export chronos

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
    raise newException(ApatheiaSignalErr, res.error())
  result.signal = res.get()
  result.chan = allocSharedChannel[T]()

proc send*[T](c: SignalQueue[T], msg: sink T): Result[void, string] {.raises: [].} =
  ## Sends a message to a thread. `msg` is copied.
  try:
    c.chan[].send(msg)
  except Exception as exc:
    result = err exc.msg

  let res = c.signal.fireSync()
  if res.isErr():
    let msg: string = res.error()
    result = err msg
  result = ok()

proc trySend*[T](c: SignalQueue[T], msg: sink T): bool =
  result = c.chan.trySend(msg)
  if result:
    c.signal.fireSync()

proc recv*[T](c: SignalQueue[T]): T =
  c.chan.recv()

proc tryRecv*[T](c: SignalQueue[T]): Option[T] =
  let res = c.chan.recv()
  if res.dataAvailable:
    some res.msg

proc wait*[T](c: SignalQueue[T]) {.async.} =
  await wait(c.signal)
