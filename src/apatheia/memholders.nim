
import std/tables

type
  MemHolder* = ref object of RootObj

  SeqHolder*[T] = ref object of MemHolder
    data*: seq[T]

  StrHolder*[T] = ref object of MemHolder
    data*: string

var memHolderTable = newTable[uint, seq[MemHolder]]()

proc storeMemoryHolder*[T: uint](id: T, mem: MemHolder) {.gcsafe, raises: [].} =
  {.cast(gcsafe).}:
    memHolderTable[].withValue(id, value):
      value[].add(mem)
    do:
      memHolderTable[id] = @[mem]

proc releaseMemoryHolder*[T: uint](id: T) {.gcsafe, raises: [].} =
  {.cast(gcsafe).}:
    memHolderTable.del(id)
