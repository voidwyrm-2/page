type
  Symbol* = ref object of NpsValue
    name: string

func newNpsSymbol*(name: string): Symbol =
  Symbol(kind: tSymbol, name: name)

method copy*(self: Symbol): NpsValue =
  self

method `==`*(self: Symbol, b: NpsValue): bool =
  case b.kind
  of tSymbol:
    self.name == Symbol(b).name
  else:
    procCall `==`(self, b)

method format*(self: Symbol): string =
  self.name

method debug*(self: Symbol): string =
  "/" & self.name

func value*(self: Symbol): string =
  self.name
