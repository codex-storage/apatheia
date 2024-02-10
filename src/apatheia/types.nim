
type
  ApatheiaException* = ref object of CatchableError
  ApatheiaSignalErr* = ref object of ApatheiaException
