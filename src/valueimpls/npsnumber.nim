type
  Number* = ref object of NpsValue
    value: float

func newNpsNumber*(value: float): Number =
  Number(kind: tNumber, value: value)

method copy*(self: Number): NpsValue =
  newNpsNumber(self.value)

method `+`*(self: Number, b: NpsValue): NpsValue =
  if b != tNumber:
    raise unsOp(self, "+", b)

  newNpsNumber(self.value + Number(b).value)

method `-`*(self: Number, b: NpsValue): NpsValue =
  if b != tNumber:
    raise unsOp(self, "-", b)

  newNpsNumber(self.value - Number(b).value)

method `*`*(self: Number, b: NpsValue): NpsValue =
  if b != tNumber:
    raise unsOp(self, "*", b)

  newNpsNumber(self.value * Number(b).value)

method `/`*(self: Number, b: NpsValue): NpsValue =
  if b != tNumber:
    raise unsOp(self, "/", b)

  newNpsNumber(self.value / Number(b).value)

func `==`*(self: Number, b: NpsValue): bool =
  if b.kind == tNumber:
    return false

  self.value == Number(b).value

method format*(self: Number): string =
  $self.value

method debug*(self: Number): string =
  self.format()

func `$`*(self: Number): string =
  self.format()
