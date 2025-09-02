type
  List* = ref object of NpsValue
    items: seq[NpsValue]

func newNpsList*(items: seq[NpsValue]): List =
  List(kind: tList, items: items)

method copy*(self: List): NpsValue =
  self

method debug*(self: List): string =
  let fmtItems = collect:
    for val in self.items:
      val.debug()

  "[" & fmtItems.join(" ") & "]"
