import ../waterpark, std/db_postgres

export db_postgres, add, take, items

type PostgresPool* = Pool[DbConn]

proc newPostgresPool*(
  initialSize: int,
  connection, user, password, database: string
): PostgresPool =
  ## Creates a new pool of Postgres database connections.
  result = newPool[DbConn]()
  for _ in 0 ..< initialSize:
    result.add(open(connection, user, password, database))

proc close*(pool: PostgresPool) {.raises: [], gcsafe.} =
  ## Closes the database connections in the pool then deallocates the pool.
  for entry in pool:
    entry.close()
  pool.close()
