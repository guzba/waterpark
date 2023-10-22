import mummy, mummy/routers, waterpark/sqlite, std/strutils

## This example demonstrates using a pool of SQLite connections to safely reuse
## connections in Mummy HTTP request handlers.
##
## This example also demonstrates using multiple pools of different sizes.
##
## For SQLite, only one writer can be writing at a time whereas many can read.
## While this is not necessary, using separate read and write pools could enable
## you to have better insight into what requests are waiting for reads vs writes.

let
  readPool = newSqlitePool(10, "example.sqlite3")
  writePool = newSqlitePool(1, "example.sqlite3")

# For example purposes, set up a dummy table
writePool.withConnnection conn:
  conn.exec(sql"create table if not exists table1(id primary key, count int)")
  conn.exec(sql"insert or replace into table1 values (0, 0)")

# A request to /get will return the count
proc getHandler(request: Request) =
  var count: int
  readPool.withConnnection reader:
    count = parseInt(reader.getValue(sql"select count from table1 limit 1"))

  # ^ This is shorthand for:
  # let reader = readPool.borrow() # Take a SQLite connection from the pool
  # try:
  #   count = parseInt(reader.getValue(sql"select count from table1 limit 1"))
  # finally:
  #   readPool.recycle(reader) # Return the SQLite connection to the pool

  var headers: HttpHeaders
  headers["Content-Type"] = "text/plain"
  request.respond(200, headers, "Count: " & $count & "\n")

# A request to /inc will increase the count by 1
proc incHandler(request: Request) =
  writePool.withConnnection writer:
    writer.exec(sql"update table1 set count = count + 1")

  var headers: HttpHeaders
  headers["Content-Type"] = "text/plain"
  request.respond(200, headers, "Done")

var router: Router
router.get("/get", getHandler)
router.get("/inc", incHandler)

let server = newServer(router)
echo "Serving on http://localhost:8080"
server.serve(Port(8080))
