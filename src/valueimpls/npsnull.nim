type
  Null* = ref object of NpsValue

func newNpsNull*(): Null =
  Null(kind: tNull)

method copy*(self: Null): NpsValue =
  self

method `==`*(self: Null, b: NpsValue): bool =
  b.kind == tNull

method debug*(self: Null): string =
  "null"
