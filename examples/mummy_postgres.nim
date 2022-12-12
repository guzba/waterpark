import mummy, mummy/routers, waterpark/postgres, std/strutils

## This example demonstrates using a pool of Postgres connections to safely reuse
## connections in Mummy HTTP request handlers.

# To run and use this example, you'd need to set up the matching Postgres user
# and table. Kind of a pain. Fortunately, you don't necessarily need to
# see how creating a Postgres pool works and how you can use it in an HTTP
# request handler.

# You can swap to `import waterpark/mysql` and `newMySqlPool` if using MySQL.

let pool = newPostgresPool(3, "localhost", "pguser", "dietcoke", "test")

proc indexHandler(request: Request) =
  var count: int

  pool.borrowConn conn:
    count = parseInt(conn.getValue(sql"select count from table1 limit 1"))

  # ^ This is shorthand for:
  # let conn = pool.borrow() # Take a Postgres connection from the pool
  # try:
  #   count = parseInt(conn.getValue(sql"select count from table1 limit 1"))
  # finally:
  #   pool.recycle(conn) # Return the Postgres connection to the pool

  var headers: HttpHeaders
  headers["Content-Type"] = "text/plain"
  request.respond(200, headers, "Count: " & $count & "\n")

var router: Router
router.get("/", indexHandler)

let server = newServer(router)
echo "Serving on http://localhost:8080"
server.serve(Port(8080))
