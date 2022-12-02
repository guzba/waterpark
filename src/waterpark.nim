import std/sets, std/locks

type
  Pool*[T] = ptr PoolObj[T]

  PoolObj[T] = object
    entries: HashSet[T]
    lock: Lock
    cond: Cond

proc newPool*[T](): Pool[T] =
  ## Creates a new thread-safe pool.
  when T isnot (ptr object):
    {.error: "Entries in the pool must be ptr objects".}
  result = cast[Pool[T]](allocShared0(sizeof(PoolObj[T])))
  initLock(result.lock)
  initCond(result.cond)

proc add*[T](pool: Pool[T], t: T) {.raises: [], gcsafe.} =
  ## Adds an entry to the pool.
  var poolWasEmpty: bool
  withLock pool.lock:
    poolWasEmpty = pool.entries.len == 0
    pool.entries.incl(t)
  if poolWasEmpty:
    signal(pool.cond)

proc take*[T](pool: Pool[T]): T {.raises: [], gcsafe.} =
  ## Takes an entry from the pool. This call blocks until it can take
  ## an entry. After taking an entry, remember to add it back to the pool
  ## when you're finished with it.
  acquire(pool.lock)
  while pool.entries.len == 0:
    wait(pool.cond, pool.lock)
  try:
    result = pool.entries.pop()
  except KeyError:
    discard # Not possible
  release(pool.lock)

iterator items*[T](pool: Pool[T]): T =
  withLock pool.lock:
    for entry in pool.entries.items:
      yield entry

proc close*[T](pool: Pool[T]) {.raises: [], gcsafe.} =
  ## Deallocates the pool.
  deinitLock(pool.lock)
  deinitCond(pool.cond)
  `=destroy`(pool[])
  deallocShared(pool)
