version     = "0.1.6"
author      = "Ryan Oldenburg"
description = "Thread-safe object pools"
license     = "MIT"

srcDir = "src"

requires "nim >= 1.6.8"

when NimMajor >= 2:
    requires "db_connector >= 0.1.0"
