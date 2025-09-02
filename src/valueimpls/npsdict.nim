type
  Dictionary* = ref object of NpsValue
    dict: Dict

func newNpsDictionary*(dict: Dict): Dictionary =
  Dictionary(kind: tDict, dict: dict)

method copy*(self: Dictionary): NpsValue =
  self

func value*(self: Dictionary): Dict =
  self.dict
