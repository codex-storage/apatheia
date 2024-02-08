import std/[tables, strutils, typetraits, macros]

proc makeProcName*(s: string): string =
  result = ""
  for c in s:
    if c.isAlphaNumeric: result.add c

proc hasReturnType*(params: NimNode): bool =
  if params != nil and params.len > 0 and params[0] != nil and
     params[0].kind != nnkEmpty:
    result = true

proc firstArgument*(params: NimNode): (NimNode, NimNode) =
  if params != nil and
      params.len > 0 and
      params[1] != nil and
      params[1].kind == nnkIdentDefs:
    result = (ident params[1][0].strVal, params[1][1])
  else:
    result = (ident "", newNimNode(nnkEmpty))

iterator paramsIter*(params: NimNode): tuple[name, ntype: NimNode] =
  for i in 1 ..< params.len:
    let arg = params[i]
    let argType = arg[^2]
    for j in 0 ..< arg.len-2:
      yield (arg[j], argType)

proc identPub*(name: string): NimNode =
  result = nnkPostfix.newTree(newIdentNode("*"), ident name)

proc signalTuple*(sig: NimNode): NimNode =
  let otp = nnkEmpty.newTree()
  # echo "signalObjRaw:sig1: ", sig.treeRepr
  let sigTyp =
    if sig.kind == nnkSym: sig.getTypeInst
    else: sig.getTypeInst
  # echo "signalObjRaw:sig2: ", sigTyp.treeRepr
  let stp =
    if sigTyp.kind == nnkProcTy:
      sig.getTypeInst[0]
    else:
      sigTyp.params()
  let isGeneric = false

  # echo "signalObjRaw:obj: ", otp.repr
  # echo "signalObjRaw:obj:tr: ", otp.treeRepr
  # echo "signalObjRaw:obj:isGen: ", otp.kind == nnkBracketExpr
  # echo "signalObjRaw:sig: ", stp.repr

  var args: seq[NimNode]
  for i in 2..<stp.len:
    args.add stp[i]

  result = nnkTupleConstr.newTree()
  if isGeneric:
    template genArgs(n): auto = n[1][1]
    var genKinds: Table[string, NimNode]
    for i in 1..<stp.genArgs.len:
      genKinds[repr stp.genArgs[i]] = otp[i]
    for arg in args:
      result.add genKinds[arg[1].repr]
  else:
    # genKinds
    # echo "ARGS: ", args.repr
    for arg in args:
      result.add arg[1]
  # echo "ARG: ", result.repr
  # echo ""
  if result.len == 0:
    # result = bindSym"void"
    result = quote do:
      tuple[]

proc mkParamsVars*(paramsIdent, paramsType, params: NimNode): NimNode =
  ## Create local variables for each parameter in the actual RPC call proc
  if params.isNil: return

  result = newStmtList()
  var varList = newSeq[NimNode]()
  var cnt = 0
  for paramid, paramType in paramsIter(params):
    let idx = newIntLitNode(cnt)
    let vars = quote do:
      var `paramid`: `paramType` = `paramsIdent`[`idx`]
    varList.add vars
    cnt.inc()
  result.add varList
  # echo "paramsSetup return:\n", treeRepr result

proc mkParamsType*(paramsIdent, paramsType, params, genericParams: NimNode): NimNode =
  ## Create a type that represents the arguments for this rpc call
  ## 
  ## Example: 
  ## 
  ##   proc multiplyrpc(a, b: int): int {.rpc.} =
  ##     result = a * b
  ## 
  ## Becomes:
  ##   proc multiplyrpc(params: RpcType_multiplyrpc): int = 
  ##     var a = params.a
  ##     var b = params.b
  ##   
  ##   proc multiplyrpc(params: RpcType_multiplyrpc): int = 
  ## 
  if params.isNil: return

  var tup = quote do:
    type `paramsType` = tuple[]
  for paramIdent, paramType in paramsIter(params):
    # processing multiple variables of one type
    tup[0][2].add newIdentDefs(paramIdent, paramType)
  result = tup
  result[0][1] = genericParams.copyNimTree()
  # echo "mkParamsType: ", genericParams.treeRepr

