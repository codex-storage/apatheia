
import std/[macros, strutils]

import macroutils

import jobs
export jobs

template checkParamType*(obj: object): auto =
  for name, field in obj.fieldPairs():
    echo "field name: ", name
  obj

template checkParamType*(obj: typed): auto =
  obj

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
  # echo "ASYNC_TASK: call: \n", tcall.treeRepr

  let tp = mkProc(procId.procIdentAppend("Tasklet"),
                  params, body)

  var asyncBody = newStmtList()
  let tcall = newCall(ident name)
  for paramId, paramType in paramsIter(params):
    echo "param: ", paramId, " tp: ", paramType.treeRepr
    tcall.add newCall("checkParamType", paramId)
  asyncBody.add tcall
  let fn = mkProc(procId, params, asyncBody)

  # echo "asyncTask:fn:body:\n", fn.treerepr

  result = newStmtList()
  result.add tp
  result.add fn
  echo "asyncTask:body:\n", result.repr
  # echo "asyncTask:body:\n", result.treeRepr

type
  HashOptions* = object
    striped*: bool

proc doHashes*(data: openArray[byte],
               opts: HashOptions) {.asyncTask.} =
  discard

# proc doHashesRes*(data: openArray[byte],
#                opts: HashOptions): int {.asyncTask.} =
#   # echo "args: ", args.len()
#   result = 10

