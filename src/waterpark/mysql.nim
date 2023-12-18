import ../waterpark, std/sequtils, std/locks

when (NimMajor, NimMinor, NimPatch) < (2, 0, 0):
  import std/db_mysql
else:
  import db_connector/db_mysql

export db_mysql, borrow, recycle, items

type MySqlPool* = object
  pool: Pool[DbConn]

proc `==`(a, b: DbConn): bool =
  cast[pointer](a) == cast[pointer](b)

proc close*(pool: MySqlPool) =
  ## Closes the database connections in the pool then deallocates the pool.
  ## All connections should be returned to the pool before it is closed.
  let entries = toSeq(pool.pool.items)
  for entry in entries:
    entry.close()
    pool.pool.delete(entry)
  pool.pool.close()

proc newMySqlPool*(
  size: int, connection, user, password, database: string
): MySqlPool =
  ## Creates a new thead-safe pool of MySQL database connections.
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

proc borrow*(pool: MySqlPool): DbConn {.inline, raises: [], gcsafe.} =
  pool.pool.borrow()

proc recycle*(pool: MySqlPool, conn: DbConn) {.inline, raises: [], gcsafe.} =
  pool.pool.recycle(conn)

template withConnection*(pool: MySqlPool, conn, body) =
  block:
    let conn = pool.borrow()
    try:
      body
    finally:
      pool.recycle(conn)
