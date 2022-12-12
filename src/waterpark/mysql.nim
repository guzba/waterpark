import ../waterpark, std/db_mysql, std/sequtils, std/locks

export db_mysql, borrow, recycle, items

type MySqlPool* = object
  pool: Pool[DbConn]

proc newMySqlPool*(
  size: int, connection, user, password, database: string
): MySqlPool =
  ## Creates a new thead-safe pool of MySQL database connections.
  result.pool = newPool[DbConn]()
  for _ in 0 ..< size:
    result.pool.recycle(open(connection, user, password, database))

proc borrow*(pool: MySqlPool): DbConn {.inline, raises: [], gcsafe.} =
  pool.pool.borrow()

proc recycle*(pool: MySqlPool, conn: DbConn) {.inline, raises: [], gcsafe.} =
  pool.pool.recycle(conn)

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

template borrowConn*(pool: MySqlPool, conn, body) =
  block:
    let conn = pool.borrow()
    try:
      body
    finally:
      pool.recycle(conn)
