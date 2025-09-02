type
  Symbol* = ref object of NpsValue
    value: string

func newNpsSymbol*(name: string): Symbol =
  Symbol(kind: tSymbol, value: name)

method format*(self: Symbol): string =
  self.value

method debug*(self: Symbol): string =
  "/" & self.value

func `$`*(self: Symbol): string =
  self.format()
