# Weave
# Copyright (c) 2019 Mamy André-Ratsimbazafy
# Licensed and distributed under either of
#   * MIT license (license terms in the root directory or at http://opensource.org/licenses/MIT).
#   * Apache v2 license (license terms in the root directory or at http://www.apache.org/licenses/LICENSE-2.0).
# at your option. This file may not be copied, modified, or distributed except according to those terms.

# This deadlocks or Illegal storage access :/

import
  # Stdlib
  system/ansi_c, strformat, os, strutils, cpuinfo,
  threadpool,
  # bench
  ../wtime

proc dfs(depth, breadth: int): uint32 =
  if depth == 0:
    return 1

  # We could use alloca to avoid heap allocation here
  var sums = newSeq[Flowvar[uint32]](breadth)

  for i in 0 ..< breadth:
    sums[i] = spawn dfs(depth - 1, breadth)

  for i in 0 ..< breadth:
    result += ^sums[i]

proc test(depth, breadth: int): uint32 =
  result = ^spawn(dfs(depth, breadth))

proc main() =

  var
    depth = 8
    breadth = 8
    answer: uint32
    nthreads: int

  # The standard lib threadpool does not support environment variable
  nthreads = countProcessors()

  if paramCount() == 0:
    let exeName = getAppFilename().extractFilename()
    echo &"Usage: {exeName} <depth:{depth}> <breadth:{breadth}>"
    echo &"Running with default config depth = {depth} and breadth = {breadth}"

  if paramCount() >= 1:
    depth = paramStr(1).parseInt()
  if paramCount() == 2:
    breadth = paramStr(2).parseInt()
  if paramCount() > 2:
    let exeName = getAppFilename().extractFilename()
    echo &"Usage: {exeName} <depth:{depth}> <breadth:{breadth}>"
    echo &"Up to 2 parameters are valid. Received {paramCount()}"
    quit 1

  # Staccato benches runtime init and exit as well
  let start = wtime_usec()

  answer = test(depth, breadth)
  sync()

  let stop = wtime_usec()

  echo "Scheduler:  Nim threadpool (standard lib)"
  echo "Benchmark:  dfs"
  echo "Threads:    ", nthreads
  echo "Time(us)    ", stop - start
  echo "Output:     ", answer

  quit 0

main()
