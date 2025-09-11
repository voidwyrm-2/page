type
  String* = ref object of NpsValue
    value: string

func newNpsString*(value: string): String =
  String(kind: tString, value: value)

method copy*(self: String): NpsValue =
  self

method `==`*(self: String, b: NpsValue): bool =
  case b.kind
  of tString:
    self.value == String(b).value
  else:
    procCall `==`(self, b)

method len*(self: String): int =
  self.value.len()

method format*(self: String): string =
  self.value

method debug*(self: String): string =
  "(" & self.value & ")"

func value*(self: String): string =
  self.value
