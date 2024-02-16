
import std/tables

import ./types
export types

type
  MemHolder* = ref object of RootObj

  SeqHolder*[T] = ref object of MemHolder
    data*: seq[T]

  StrHolder*[T] = ref object of MemHolder
    data*: string

var memHolderTable = newTable[uint, seq[MemHolder]]()

proc retainMemory*(id: JobId, mem: MemHolder) {.gcsafe, raises: [].} =
  {.cast(gcsafe).}:
    memHolderTable[].withValue(id, value):
      value[].add(mem)
    do:
      memHolderTable[id] = @[mem]

proc releaseMemory*(id: JobId) {.gcsafe, raises: [].} =
  {.cast(gcsafe).}:
    memHolderTable.del(id)

proc retainedMemoryCount*(): int {.gcsafe, raises: [].} =
  {.cast(gcsafe).}:
    memHolderTable.len()
