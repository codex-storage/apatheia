
type
  ApatheiaException* = object of CatchableError
  ApatheiaSignalErr* = object of ApatheiaException

  JobId* = uint ## job id, should match `future.id()`