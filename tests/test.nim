import waterpark

block:
  type
    TestType = object
      val: int

  var added: TestType
  added.val = 3

  let pool = newPool[TestType]()
  pool.recycle(added)

  let taken = pool.borrow()

  doAssert added.val == taken.val

  pool.close()

block:
  type
    TestType = ptr TestTypeObj

    TestTypeObj = object
      val: int

  let added = cast[TestType](allocShared0(sizeof(TestTypeObj)))
  added.val = 3

  let pool = newPool[TestType]()
  pool.recycle(added)

  let taken = pool.borrow()

  doAssert added.val == taken.val

  # Destroy the pool entries
  for entry in pool:
    deallocShared(entry)

  pool.close()
