type
  Dictionary* = ref object of NpsValue
    dict: Dict

proc newNpsDictionary*(dict: Dict): Dictionary =
  logger.logdv("Creating new Dictionary")
  result = Dictionary(kind: tDict, dict: dict)
  logger.logdv("Dictionary created")

method copy*(self: Dictionary): NpsValue =
  self

method len*(self: Dictionary): int =
  self.dict.len()

method debug(self: Dictionary): string =
  "-dict-"

func value*(self: Dictionary): Dict =
  self.dict
