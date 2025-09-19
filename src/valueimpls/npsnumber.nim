type
  Number* = ref object of NpsValue
    value: float

func newNpsNumber*(value: float): Number =
  Number(kind: tNumber, value: value)

method copy*(self: Number): NpsValue =
  self

template opimpl(name: string, op: untyped) =
  case b.kind
  of tNumber:
    result = newNpsNumber(op(self.value, Number(b).value))
  else:
    unsOp(self, name, b)

method `+`*(self: Number, b: NpsValue): NpsValue =
  opimpl("add", `+`)

method `-`*(self: Number, b: NpsValue): NpsValue =
  opimpl("sub", `-`)

method `*`*(self: Number, b: NpsValue): NpsValue =
  opimpl("mul", `*`)

method `/`*(self: Number, b: NpsValue): NpsValue =
  opimpl("div", `/`)

method `//`*(self: Number, b: NpsValue): NpsValue =
  case b.kind
  of tNumber:
    let f = self.value / Number(b).value
    result = newNpsNumber(float(int(f)))
  else:
    unsOp(self, "idiv", b)

method `%`*(self: Number, b: NpsValue): NpsValue =
  opimpl("mod", `mod`)

method `^`*(self: Number, b: NpsValue): NpsValue =
  opimpl("exp", `^`)

method `==`*(self: Number, b: NpsValue): bool =
  case b.kind
  of tNumber:
    self.value == Number(b).value
  else:
    false

method `>`*(self: Number, b: NpsValue): bool =
  case b.kind
  of tNumber:
    result = self.value > Number(b).value
  else:
    unsOp(self, "gt", b)

method `<`*(self: Number, b: NpsValue): bool =
  case b.kind
  of tNumber:
    result = self.value < Number(b).value
  else:
    unsOp(self, "lt", b)

method format*(self: Number): string =
  result = $self.value
  result.trimZeros('.')

method debug*(self: Number): string =
  self.format()

func value*(self: Number): float =
  self.value
