type
  Dictionary* = ref object of NpsValue
    dict: Dict

func newNpsDictionary*(dict: Dict): Dictionary =
  Dictionary(kind: tDict, dict: dict)


method copy*(self: Dictionary): NpsValue =
  self

method debug(self: Dictionary): string =
  "-dict-"

func value*(self: Dictionary): Dict =
  self.dict
