import waterpark

type
  TestType = ptr TestTypeObj

  TestTypeObj = object
    val: int

let added = cast[TestType](allocShared0(sizeof(TestTypeObj)))
added.val = 3

let pool = newPool[TestType]()
pool.add(added)

let taken = pool.take()

doAssert added.val == taken.val

# Clean up custom pool
for entry in pool:
  deallocShared(entry)
pool.close()
