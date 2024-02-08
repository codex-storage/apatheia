

proc doHashes*[T: object](args: openArray[T], obj: Object) {.asyncTask.} =

  let x = args


proc doHashesTask*(args: seq[Data]) =
  ...

proc doHashes*(args: seq[Data]) {.async.} =
  # setup signals ... etc
  # memory stuffs
  # create future
  let argsPtr = addr args[0]
  let argsLen = args.len()
  GC_ref(args)

  doHashes(toOpenArray(argsPtr, argsLen))
  GC_unref(args)
  

proc processHashes*(args: seq[Data]) {.async.} =

  ## do some processing on another thread
  let res = await doHashes(args)

