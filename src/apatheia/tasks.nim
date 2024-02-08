
import std/[macros, strutils]

import macroutils

template checkParamType(obj: object) =
  for name, field in obj.fieldPairs():
    echo "field name: ", name


macro asyncTask*(p: untyped): untyped =

  let
    procId = p[0]
    procLineInfo = p.lineInfoObj
    genericParams = p[2]
    params = p[3]
    pragmas = p[4]
    body = p[6]
    name = repr(procId).strip(false, true, {'*'})
  
  echo "\nASYNC_TASK: "
  echo "name: ", name
  echo "hasReturnType: ", hasReturnType(params)
  echo "getReturnType: ", params.getReturnType().treeRepr
  echo "generics: ", genericParams.treeRepr
  echo "params: \n", params.treeRepr
  # echo "ASYNC_TASK: call: \n", tcall.treeRepr

  var asyncBody = newStmtList()
  for paramId, paramType in paramsIter(params):
    echo "param: ", paramId, " tp: ", paramType.treeRepr
    asyncBody.add newCall("checkParamType", paramId)
  # echo "asyncTask:checks:\n", asyncBody.repr
  # let tcall = mkCall(ident"tester", params)
  
  echo "asyncTask:body:\n", body.repr
  let taskProc = mkProc(procId, params, body)

  result = newStmtList()
  result.add taskProc
  echo "asyncTask:body:\n", result.repr
  # echo "asyncTask:body:\n", result.treeRepr

type
  HashOptions* = object
    striped*: bool

proc doHashes*(data: openArray[byte],
               opts: HashOptions) {.asyncTask.} =
  # echo "args: ", args.len()
  discard

proc doHashesRes*(data: openArray[byte],
               opts: HashOptions): int {.asyncTask.} =
  discard
  # echo "args: ", args.len()
  result = 10


when false:
  proc doHashesTask*(args: seq[Data]) =
    discard

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

