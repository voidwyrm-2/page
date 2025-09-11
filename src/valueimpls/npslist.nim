type
  List* = ref object of NpsValue
    items: seq[NpsValue]

func newNpsList*(items: seq[NpsValue]): List =
  List(kind: tList, items: items)

func newNpsList*(len: Natural): List =
  var items = newSeq[NpsValue](len)

  for i in 0..<len:
    items[i] = newNpsNull()

  newNpsList(items)

method copy*(self: List): NpsValue =
  self

method len*(self: List): int =
  self.items.len()

method debug*(self: List): string =
  let fmtItems = collect:
    for val in self.items:
      val.debug()

  "[" & fmtItems.join(" ") & "]"

func checkInd(self: List, ind: Natural) =
  if self.items.len() < ind:
    raise newNpsError(fmt"Index '{ind}' not in range for the list of length {self.items.len()}")

func `[]`*(self: List, ind: Natural): NpsValue =
  self.checkInd(ind)
  self.items[ind]

func `[]=`*(self: List, ind: Natural, val: NpsValue) =
  self.checkInd(ind)
  self.items[ind] = val

func value*(self: List): seq[NpsValue] =
  self.items
