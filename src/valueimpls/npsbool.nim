type
  Bool* = ref object of NpsValue
    value: bool

func newNpsBool*(value: bool): Bool =
  Bool(kind: tBool, value: value)

method copy*(self: Bool): NpsValue =
  self

method `==`*(self: Bool, b: NpsValue): bool =
  case b.kind
  of tBool:
    self.value == Bool(b).value
  else:
    procCall `==`(self, b)

method format*(self: Bool): string =
  $self.value

method debug*(self: Bool): string =
  $self.value

func value*(self: Bool): bool =
  self.value
