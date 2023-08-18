when (NimMajor, NimMinor, NimPatch) < (2, 0, 0):
  when not defined(gcArc) and not defined(gcOrc):
    {.error: "Using --mm:arc or --mm:orc is required by Waterpark.".}

import std/locks, std/random

type
  Pool*[T] = ptr PoolObj[T]

  PoolObj[T] = object
    entries: seq[T]
    lock: Lock
    cond: Cond
    r: Rand

proc newPool*[T](): Pool[T] =
  ## Creates a new thread-safe pool.
  when T is (ref object):
    {.error: "Entries in the pool must not be ref objects".}
  result = cast[Pool[T]](allocShared0(sizeof(PoolObj[T])))
  initLock(result.lock)
  initCond(result.cond)
  result.r = initRand(2023)

proc borrow*[T](pool: Pool[T]): T {.raises: [], gcsafe.} =
  ## Takes an entry from the pool. This call blocks until it can take
  ## an entry. After taking an entry remember to add it back to the pool
  ## when you're finished with it.
  acquire(pool.lock)
  while pool.entries.len == 0:
    wait(pool.cond, pool.lock)
  result = pool.entries.pop()
  release(pool.lock)

proc recycle*[T](pool: Pool[T], t: T) {.raises: [], gcsafe.} =
  ## Returns an entry to the pool.
  withLock pool.lock:
    pool.entries.add(t)
    pool.r.shuffle(pool.entries)
  signal(pool.cond)

proc delete*[T](pool: Pool[T], entry: T) {.raises: [], gcsafe.} =
  ## Removes the entry from the pool.
  withLock pool.lock:
    let index = pool.entries.find(entry)
    if index != -1:
      pool.entries.del(index)

iterator items*[T](pool: Pool[T]): T =
  withLock pool.lock:
    for entry in pool.entries.items:
      yield entry

proc close*[T](pool: Pool[T]) {.raises: [].} =
  ## Deallocates the pool. Any entries should be destroyed first.
  deinitLock(pool.lock)
  deinitCond(pool.cond)
  `=destroy`(pool[])
  deallocShared(pool)
