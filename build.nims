
import std/[os, strutils]

task test, "unit tests":
  for file in listFiles("tests"):
    let name = file.splitPath().tail
    if name.startsWith("t") and name.endsWith(".nim"):
      exec "nim c -r " & file
