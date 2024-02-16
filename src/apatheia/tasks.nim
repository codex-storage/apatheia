import std/[macros, strutils]

import macroutils

import jobs
export jobs

# TODO: make these do something useful or remove them

template convertParamType*[T](obj: OpenArrayHolder[T]): auto =
  static:
    echo "CONVERTPARAMTYPE:: ", $typeof(obj)
  obj.toOpenArray()

template convertParamType*(obj: typed): auto =
  obj

macro asyncTask*(p: untyped): untyped =
  ## Pragma to transfer a proc into a "tasklet" which runs
  ## the proc body in a separate thread and returns the result
  ## in an async compatible manner.
  ## 

  let
    procId = p[0]
    # procLineInfo = p.lineInfoObj
    # genericParams = p[2]
    params = p[3]
    # pragmas = p[4]
    body = p[6]
    name = repr(procId).strip(false, true, {'*'})

  if not hasReturnType(params):
    error("tasklet definition must have return type", p)

  # setup inner tasklet proc
  let tp = mkProc(procId.procIdentAppend("Tasklet"), params, body)

  # setup async wrapper code
  var asyncBody = newStmtList()
  let tcall = newCall(ident(name & "Tasklet"))
  for paramId, paramType in paramsIter(params):
    tcall.add newCall("convertParamType", paramId)
  asyncBody = quote:
    let val {.inject.} = `tcall`
    discard jobResult.queue.send((jobResult.id, val))

  let retType =
    if not hasReturnType(params):
      ident"void"
    else:
      params.getReturnType()

  let jobArg = nnkIdentDefs.newTree(
    ident"jobResult", nnkBracketExpr.newTree(ident"JobResult", retType), newEmptyNode()
  )
  var asyncParams = nnkFormalParams.newTree()
  asyncParams.add newEmptyNode()
  asyncParams.add jobArg
  for i, p in params[1..^1]:
    let pt = p[1]
    if pt.kind == nnkBracketExpr and pt[0].repr == "openArray":
      # special case openArray to support special OpenArrayHolder from jobs module
      p[1] = nnkBracketExpr.newTree(ident"OpenArrayHolder", pt[1])
      asyncParams.add p
    else:
      asyncParams.add p


  let fn = mkProc(procId, asyncParams, asyncBody)

  result = newStmtList()
  result.add tp
  result.add fn

  when isMainModule:
    echo "asyncTask:body:\n", result.repr

when isMainModule:
  type HashOptions* = object
    striped*: bool

  proc doHashes*(data: openArray[byte], opts: HashOptions): float {.asyncTask.} =
    echo "hashing"
