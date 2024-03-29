import std/options
import ./types

import results
import chronos
import chronos/threadsync

export types
export options
export threadsync
export chronos

type ChanPtr[T] = ptr Channel[T]

proc allocSharedChannel[T](): ChanPtr[T] =
  cast[ChanPtr[T]](allocShared0(sizeof(Channel[T])))

type SignalQueue*[T] = object
  signal: ThreadSignalPtr
  chan*: ChanPtr[T]

proc dispose*[T](val: SignalQueue[T]) =
  ## Call to properly dispose of a SignalQueue.
  deallocShared(val.chan)
  discard val.signal.close()

proc newSignalQueue*[T](
    maxItems: int = 0
): SignalQueue[T] {.raises: [ApatheiaSignalErr].} =
  ## Create a signal queue compatible with Chronos async.
  let res = ThreadSignalPtr.new()
  if res.isErr():
    raise newException(ApatheiaSignalErr, res.error())
  result.signal = res.get()
  result.chan = allocSharedChannel[T]()
  result.chan[].open(maxItems)

proc send*[T](c: SignalQueue[T], msg: sink T): Result[void, string] {.raises: [].} =
  ## Sends a message to a thread. `msg` is copied.
  ## Note: currently non-blocking but future iterations may become blocking.
  ## 
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
  ## Trys to sends a message to a thread. `msg` is copied. Non-blocking.
  result = c.chan.trySend(msg)
  if result:
    c.signal.fireSync()

proc recv*[T](c: SignalQueue[T]): Result[T, string] =
  ## Receive item from queue, blocking.
  try:
    result = ok c.chan[].recv()
  except Exception as exc:
    result = err exc.msg

proc tryRecv*[T](c: SignalQueue[T]): Option[T] =
  ## Try to receive item from queue, non-blocking.
  let res = c.chan.recv()
  if res.dataAvailable:
    some res.msg

proc wait*[T](c: SignalQueue[T]): Future[Result[T, string]] {.async.} =
  ## Async compatible receive from queue. Pauses async execution until
  ## an item is received from the queue
  await wait(c.signal)
  return c.recv()
