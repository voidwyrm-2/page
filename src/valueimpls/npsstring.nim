type
  String* = ref object of NpsValue
    value: string

func newNpsString*(value: string): String =
  String(kind: tString, value: value)

method copy*(self: String): NpsValue =
  newNpsString(self.value)

method `==`*(self: String, b: NpsValue): bool =
  case b.kind
  of tString:
    self.value == String(b).value
  else:
    procCall `==`(self, b)

method format*(self: String): string =
  self.value

method debug*(self: String): string =
  "(" & self.value & ")"
