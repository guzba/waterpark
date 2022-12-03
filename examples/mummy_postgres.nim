import mummy, waterpark/postgres, std/strutils

# To run and use this example, you'd need to set up the matching Postgres user
# and table. Kind of a pain. Fortunately, you don't necessarily need to
# see how creating a Postgres pool works and how you can use it in an HTTP
# request handler.

let pool = newPostgresPool(3, "localhost", "pguser", "dietcoke", "test")

proc handler(request: Request) =
  case request.uri:
  of "/":
    if request.httpMethod == "GET":
      var count: int

      let conn = pool.take() # Take a Postgres connection from the pool
      try:
        count = parseInt(conn.getValue(sql"select count from table1 limit 1"))
      finally:
        pool.add(conn) # Return the Postgres connection to the pool

      var headers: HttpHeaders
      headers["Content-Type"] = "text/plain"
      request.respond(200, headers, "Count: " & $count & "\n")
    else:
      request.respond(405)
  else:
    request.respond(404)

let server = newServer(handler)
echo "Serving on http://localhost:8080"
server.serve(Port(8080))
