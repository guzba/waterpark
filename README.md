# Waterpark

`nimble install waterpark`

![Github Actions](https://github.com/guzba/waterpark/workflows/Github%20Actions/badge.svg)

[API reference](https://guzba.github.io/waterpark/)

Waterpark provides thread-safe object pools and a generic `Pool[T]` to create your own.

Currently there are 3 built-in pools:

* `import waterpark/postgres`
* `import waterpark/mysql`
* `import waterpark/sqlite`

Adding more pools is planned, including for Redis etc.

A great use-case for these thread-safe pools is for database connections when running
a multithreaded HTTP server like [Mummy](https://github.com/guzba/mummy).

Using Waterpark connection pools for multiple different databases is no problem. You can create one or more pools for each database without any trouble. See [this example](https://github.com/guzba/waterpark/blob/master/examples/mummy_sqlite.nim) to get an idea of how this works.

## Example

The following example shows a Postgres database connection pool being used in a Mummy HTTP request handler.

```nim
import mummy, mummy/routers, waterpark/postgres, std/strutils

let pg = newPostgresPool(3, "localhost", "pguser", "dietcoke", "test")

proc indexHandler(request: Request) =
  var count: int

  pg.withConnection conn:
    count = parseInt(conn.getValue(sql"select count from table1 limit 1"))

  # ^ This is shorthand for:
  # let conn = pg.borrow() # Take a Postgres connection from the pool
  # try:
  #   count = parseInt(conn.getValue(sql"select count from table1 limit 1"))
  # finally:
  #   pg.recycle(conn) # Return the Postgres connection to the pool

  var headers: HttpHeaders
  headers["Content-Type"] = "text/plain"
  request.respond(200, headers, "Count: " & $count & "\n")

var router: Router
router.get("/", indexHandler)

let server = newServer(router)
echo "Serving on http://localhost:8080"
server.serve(Port(8080))
```

There are more examples in the [examples/](https://github.com/guzba/waterpark/tree/master/examples) directory of this repo.

## Tips

* When a new connection pool is created for Postgres, MySQL, SQLite etc, a size for the pool is given. That number of database connections is opened immediately. If this does not succeed, an exception is raised so you know right away. This ensures you know your server can talk to your database long before you begin listening for incoming requests.

* When a thread wants to borrow from a pool, either that thread will receive a connection from the pool of available connections immediately or it will block until a connection is available. This means you don't need to worry about something causing runaway connections to be opened, potentially taking down your database server.

## Testing

`nimble test`
