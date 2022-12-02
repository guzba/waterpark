import mummy, waterpark/pg

# For this example to work you'll need a running Postgres database
# along with entering the correct connection parameters below.

# While this may make running the example more challenging, it remains
# a simple way to see how to use the Postgres pool.

let pool = newPgPool(3, "localhost", "", "", "")

# proc handler(request: Request) =
#   case request.uri:
#   of "/":
#     if request.httpMethod == "GET":
#       var count: int

#       let conn = pool.take() # Take a Postgres connection from the pool
#       try:
#         discard
#       finally:
#         pool.add(conn) # Return the postgres connection to the pool

#       var headers: HttpHeaders
#       headers["Content-Type"] = "text/plain"
#       request.respond(200, headers, $count)
#     else:
#       request.respond(405)
#   else:
#     request.respond(404)

# let server = newServer(handler)
# echo "Serving on http://localhost:8080"
# server.serve(Port(8080))
