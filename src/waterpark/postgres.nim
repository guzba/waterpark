import ../waterpark, std/sequtils, std/locks

when (NimMajor, NimMinor, NimPatch) < (2, 0, 0):
  import std/db_postgres
else:
  import db_connector/db_postgres

export db_postgres, borrow, recycle, items

type PostgresPool* = object
  pool: Pool[DbConn]

proc close*(pool: PostgresPool) =
  ## Closes the database connections in the pool then deallocates the pool.
  ## All connections should be returned to the pool before it is closed.
  let entries = toSeq(pool.pool.items)
  for entry in entries:
    entry.close()
    pool.pool.delete(entry)
  pool.pool.close()

proc newPostgresPool*(
  size: int, connection, user, password, database: string
): PostgresPool =
  ## Creates a new thead-safe pool of Postgres database connections.
  if size <= 0:
    raise newException(CatchableError, "Invalid pool size")
  result.pool = newPool[DbConn]()
  try:
    for _ in 0 ..< size:
      result.pool.recycle(open(connection, user, password, database))
  except DbError as e:
    try:
      result.close()
    except:
      discard
    raise e

proc borrow*(pool: PostgresPool): DbConn {.inline, raises: [], gcsafe.} =
  pool.pool.borrow()

proc recycle*(pool: PostgresPool, conn: DbConn) {.inline, raises: [], gcsafe.} =
  pool.pool.recycle(conn)

template withConnection*(pool: PostgresPool, conn, body) =
  block:
    let conn = pool.borrow()
    try:
      body
    finally:
      pool.recycle(conn)
