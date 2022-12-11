# Waterpark

`nimble install waterpark`

![Github Actions](https://github.com/guzba/waterpark/workflows/Github%20Actions/badge.svg)

[API reference](https://nimdocs.com/guzba/waterpark)

Waterpark provides thread-safe object pools and a generic `Pool[T]` to create your own.

Currently there are 3 built-in pools:

* `import waterpark/postgres`
* `import waterpart/msyql`
* `import waterpart/sqlite`

Adding more pools is planned, including for Redis etc.

A great use-case for these thread-safe pools is for database connections when running
a multithreaded HTTP server like [Mummy](https://github.com/guzba/mummy).

## Example

The following example shows a Postgres database connection pool being used in a Mummy HTTP request handler.

```nim
import mummy, mummy/routers, waterpark/postgres, std/strutils

let pool = newPostgresPool(3, "localhost", "pguser", "dietcoke", "test")

proc indexHandler(request: Request) =
  var count: int

  pool.withConn conn:
    count = parseInt(conn.getValue(sql"select count from table1 limit 1"))

  var headers: HttpHeaders
  headers["Content-Type"] = "text/plain"
  request.respond(200, headers, "Count: " & $count & "\n")

var router: Router
router.get("/", indexHandler)

let server = newServer(router)
echo "Serving on http://localhost:8080"
server.serve(Port(8080))

```

## Testing

`nimble test`
