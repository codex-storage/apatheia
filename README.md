
# Apatheia

> *Apatheia* (*Greek: ἀπάθεια; from a- "without" and pathos "suffering" or "passion"*), in Stoicism, refers to a state of mind in which one is not disturbed by the passions. It might better be translated by the word equanimity than the word indifference. 

WIP utilities for using Chronos async with threading. The desire is to provide safe, pre-tested constructs for using threads with async.

Goals:

- support orc and refc
  + refc may require extra copying for data
- use event queues (e.g. channels) to/from thread pool 
  + make it easy to monitor and debug queue capacity
  + only use minimal AsyncFD handles
  + lessen pressure on the main chronos futures pending queue
- support backpressure at futures level
- benchmarking overhead
- special support for seq[byte]'s and strings with zero-copy
  + implement special but limited support zero-copy arguments on refc

