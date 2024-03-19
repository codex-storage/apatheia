
when false:
  type AnObject* = object of RootObj
    value*: int

  proc mutate(a: sink AnObject) =
    a.value = 1

  var obj = AnObject(value: 42)
  mutate(obj)
  doAssert obj.value == 42

else:
  type AnObject = object of RootObj
    value*: int

  proc `=destroy`(x: var AnObject) = 
    echo "DEST"

  proc mutate(a: sink AnObject) =
    a.value = 1

  var obj = AnObject(value: 42)
  mutate(obj)
  doAssert obj.value == 42
