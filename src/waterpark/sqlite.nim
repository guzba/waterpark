import ../waterpark, std/sequtils

when (NimMajor, NimMinor, NimPatch) < (2, 0, 0):
  import std/db_sqlite
else:
  import db_connector/db_sqlite


export db_sqlite, borrow, recycle, items

type SqlitePool* = object
  pool: Pool[DbConn]

proc close*(pool: SqlitePool) =
  ## Closes the database connections in the pool then deallocates the pool.
  ## All connections should be returned to the pool before it is closed.
  let entries = toSeq(pool.pool.items)
  for entry in entries:
    entry.close()
    pool.pool.delete(entry)
  pool.pool.close()

proc newSqlitePool*(size: int, database: string): SqlitePool =
  ## Creates a new thead-safe pool of SQLite database connections.
  if size <= 0:
    raise newException(CatchableError, "Invalid pool size")
  result.pool = newPool[DbConn]()
  try:
    for _ in 0 ..< size:
      result.pool.recycle(open(database, "", "", ""))
  except DbError as e:
    try:
      result.close()
    except:
      discard
    raise e

proc borrow*(pool: SqlitePool): DbConn {.inline, raises: [], gcsafe.} =
  pool.pool.borrow()

proc recycle*(pool: SqlitePool, conn: DbConn) {.inline, raises: [], gcsafe.} =
  pool.pool.recycle(conn)

template withConnection*(pool: SqlitePool, conn, body) =
  block:
    let conn = pool.borrow()
    try:
      body
    finally:
      pool.recycle(conn)
