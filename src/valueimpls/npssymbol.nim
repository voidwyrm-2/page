type
  Symbol* = ref object of NpsValue
    name: string

func newNpsSymbol*(name: string): Symbol =
  Symbol(kind: tSymbol, name: name)

method copy*(self: Symbol): NpsValue =
  self

method format*(self: Symbol): string =
  self.name

method debug*(self: Symbol): string =
  "/" & self.name
