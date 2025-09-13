type
  LogLevel* = enum
    llNone,
    llInfo,
    llDebug,
    llInternDebug,
    llDev

  Logger* = ref object
    file: File
    level: uint8

var logger*: Logger = nil

func newLogger*(file: File, level: uint8 = 0): Logger =
  new result
  result.file = file
  result.level = level

proc startGlobalLogger*(file: File, level: uint8 = 0) =
  logger = newLogger(file, level)

proc log*(self: Logger, msg: string, level: uint8) =
  if self != nil and self.level >= level:
    self.file.writeLine "(L" & $level & ") " & msg

proc log*(self: Logger, msg: string, level: LogLevel = llInfo) =
  self.log(msg, cast[uint8](level))

proc logd*(self: Logger, msg: string) =
  self.log(msg, llDebug)

proc logdv*(self: Logger, msg: string) =
  self.log(msg, llDev)

func level*(self: Logger): uint8 =
  self.level
