import mummy, mummy/routers, waterpark/sqlite, std/strutils

## This example demonstrates using a pool of SQLite connections to safely reuse
## connections in Mummy HTTP request handlers.

let pool = newSqlitePool(3, "example.sqlite3")

proc indexHandler(request: Request) =
  var count: int

  pool.withConnnection conn:
    count = parseInt(conn.getValue(sql"select count from table1 limit 1"))

  # ^ This is shorthand for:
  # let conn = pool.borrow() # Take a SQLite connection from the pool
  # try:
  #   count = parseInt(conn.getValue(sql"select count from table1 limit 1"))
  # finally:
  #   pool.recycle(conn) # Return the SQLite connection to the pool

  var headers: HttpHeaders
  headers["Content-Type"] = "text/plain"
  request.respond(200, headers, "Count: " & $count & "\n")

var router: Router
router.get("/", indexHandler)

let server = newServer(router)
echo "Serving on http://localhost:8080"
server.serve(Port(8080))
