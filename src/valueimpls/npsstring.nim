type
  String* = ref object of NpsValue
    value: string

func newNpsString*(value: string): String =
  String(kind: tString, value: value)

method copy*(self: String): NpsValue =
  newNpsString(self.value)

method `+`*(self: String, b: NpsValue): NpsValue =
  if b != tString:
    raise unsOp(self, "+", b)

  newNpsString(self.value & String(b).value)

method format*(self: String): string =
  self.value

method debug*(self: String): string =
  "(" & self.value & ")"

func `$`*(self: String): string =
  self.format()
