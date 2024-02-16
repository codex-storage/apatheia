import std/tables

import ./types
export types

type
  Retainer* = ref object of RootObj

  SeqRetainer*[T] = ref object of Retainer
    data*: seq[T]

  StrRetainer* = ref object of Retainer
    data*: string

var memoryRetainerTable = newTable[uint, seq[Retainer]]()

proc retainMemory*(id: JobId, mem: Retainer) {.gcsafe, raises: [].} =
  {.cast(gcsafe).}:
    memoryRetainerTable[].withValue(id, value):
      value[].add(mem)
    do:
      memoryRetainerTable[id] = @[mem]

proc releaseMemory*(id: JobId) {.gcsafe, raises: [].} =
  {.cast(gcsafe).}:
    memoryRetainerTable.del(id)

proc retainedMemoryCount*(): int {.gcsafe, raises: [].} =
  {.cast(gcsafe).}:
    memoryRetainerTable.len()
