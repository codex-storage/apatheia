# Package

version       = "0.1.0"
author        = "Jaremy Creechley"
description   = "Async support for threading primitives"
license       = "MIT"
srcDir        = "src"

# Dependencies

requires "chronos >= 4.0.0"
requires "threading"
requires "taskpools >= 0.0.5"
requires "chronicles"

include "build.nims"
