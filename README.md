# Waterpark

`nimble install waterpark`

![Github Actions](https://github.com/guzba/waterpark/workflows/Github%20Actions/badge.svg)

[API reference](https://nimdocs.com/guzba/waterpark)

Waterpark provides thread-safe object pools and a generic `Pool[T]` to create your own.

Waterpark is brand new so right now there is only one built-in pool, `waterpark/postgres`, which provides a Postgres database connection pool.

I intend to add many more pools soon, such as for MySQL, SQLite, Redis etc.

A great use-case for these thread-safe pools is for database connections when running
a multithreaded HTTP server like [Mummy](https://github.com/guzba/mummy).

## Example

The following example shows a Postgres database connection pool being used in a Mummy HTTP request handler.

```nim
let pool = newPgPool(3, "localhost", "pguser", "dietcoke", "test")

proc handler(request: Request) =
  case request.uri:
  of "/":
    if request.httpMethod == "GET":
      var count: int

      let conn = pool.take() # Take a Postgres connection from the pool
      try:
        count = parseInt(conn.getValue(sql"select count from table1 limit 1"))
      finally:
        pool.add(conn) # Return the postgres connection to the pool

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
```

## Testing

`nimble test`
