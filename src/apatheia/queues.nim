
import chronos
import chronos/threadsync

type

  AsyncQueue*[T] = object
    signal: ThreadSignalPtr
    item*: T


