type
  Number* = ref object of NpsValue
    value: float

func newNpsNumber*(value: float): Number =
  Number(kind: tNumber, value: value)

method copy*(self: Number): NpsValue =
  newNpsNumber(self.value)

method `+`*(self: Number, b: NpsValue): NpsValue =
  case b.kind
  of tNumber:
    newNpsNumber(self.value + Number(b).value)
  else:
    procCall `+`(self, b)

method `-`*(self: Number, b: NpsValue): NpsValue =
  case b.kind
  of tNumber:
    newNpsNumber(self.value - Number(b).value)
  else:
    procCall `-`(self, b)

method `*`*(self: Number, b: NpsValue): NpsValue =
  case b.kind
  of tNumber:
    newNpsNumber(self.value * Number(b).value)
  else:
    procCall `*`(self, b)

method `/`*(self: Number, b: NpsValue): NpsValue =
  case b.kind
  of tNumber:
    newNpsNumber(self.value / Number(b).value)
  else:
    procCall `/`(self, b)

func `==`*(self: Number, b: NpsValue): bool =
  if b.kind == tNumber:
    return false

  self.value == Number(b).value

method format*(self: Number): string =
  result = $self.value
  result.trimZeros('.')

method debug*(self: Number): string =
  self.format()
