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

method `//`*(self: Number, b: NpsValue): NpsValue =
  case b.kind
  of tNumber:
    let f = self.value / Number(b).value
    newNpsNumber(float(int(f)))
  else:
    procCall `//`(self, b)

method `%`*(self: Number, b: NpsValue): NpsValue =
  case b.kind
  of tNumber:
    newNpsNumber(self.value mod Number(b).value)
  else:
    procCall `%`(self, b)

method `^`*(self: Number, b: NpsValue): NpsValue =
  case b.kind
  of tNumber:
    newNpsNumber(self.value ^ Number(b).value)
  else:
    procCall `^`(self, b)

method `==`*(self: Number, b: NpsValue): bool =
  case b.kind
  of tNumber:
    self.value == Number(b).value
  else:
    procCall `==`(self, b)

method `>`*(self: Number, b: NpsValue): bool =
  case b.kind
  of tNumber:
    self.value > Number(b).value
  else:
    procCall `>`(self, b)

method `<`*(self: Number, b: NpsValue): bool =
  case b.kind
  of tNumber:
    self.value < Number(b).value
  else:
    procCall `<`(self, b)

method format*(self: Number): string =
  result = $self.value
  result.trimZeros('.')

method debug*(self: Number): string =
  self.format()

func value*(self: Number): float =
  self.value
