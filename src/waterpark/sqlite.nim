import ../waterpark, std/db_sqlite, std/sequtils

export db_sqlite, borrow, recycle, items

type SqlitePool* = object
  pool: Pool[DbConn]

proc newSqlitePool*(size: int, database: string): SqlitePool =
  ## Creates a new thead-safe pool of SQLite database connections.
  result.pool = newPool[DbConn]()
  for _ in 0 ..< size:
    result.pool.recycle(open(database, "", "", ""))

proc borrow*(pool: SqlitePool): DbConn {.inline, raises: [], gcsafe.} =
  pool.pool.borrow()

proc recycle*(pool: SqlitePool, conn: DbConn) {.inline, raises: [], gcsafe.} =
  pool.pool.recycle(conn)

proc close*(pool: SqlitePool) =
  ## Closes the database connections in the pool then deallocates the pool.
  ## All connections should be returned to the pool before it is closed.
  let entries = toSeq(pool.pool.items)
  for entry in entries:
    entry.close()
    pool.pool.delete(entry)
  pool.pool.close()

template borrowConn*(pool: SqlitePool, conn, body) =
  block:
    let conn = pool.borrow()
    try:
      body
    finally:
      pool.recycle(conn)
