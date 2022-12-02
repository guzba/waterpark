# Waterpark

`nimble install waterpark`

![Github Actions](https://github.com/guzba/waterpark/workflows/Github%20Actions/badge.svg)

[API reference](https://nimdocs.com/guzba/waterpark)

Waterpark provides thread-safe object pools and a generic `Pool[T]` to create your own.

Waterpark is brand new so right now Waterpark only has one ready-to-go pool, `waterpark/pg`, which provides a Postgres database connection pool.

I intend to add many more pools soon, such as for MySql, SQLite, Redis etc.

A great use-case for these thread-safe pools is for database connections when running
a multithreaded HTTP server like [Mummy](https://github.com/guzba/mummy).

## Example

```nim
discard
```

## Testing

`nimble test`
