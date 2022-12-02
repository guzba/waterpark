import ../waterpark, std/db_postgres

export add, take, items

type PgPool* = Pool[DbConn]

proc newPgPool*(
  initialSize: int,
  connection, user, password, database: string
): PgPool =
  ## Creates a new pool of Postgres database connections.
  result = newPool[DbConn]()
  for _ in 0 ..< initialSize:
    result.add(open(connection, user, password, database))

proc close*(pool: PgPool) {.raises: [], gcsafe.} =
  ## Closes the database connections in the pool then deallocates the pool.
  for entry in pool:
    entry.close()
  pool.close()
