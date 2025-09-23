# Package

version       = "0.23.0"
author        = "Nuclear Pasta"
description   = "A PostScript implementation"
license       = "Apache-2.0"
srcDir        = "src"
bin           = @["npscript"]


# Dependencies

requires "nim >= 2.2.4"

requires "https://github.com/jangko/nim-noise >= 0.1.10"
requires "https://github.com/voidwyrm-2/nargparse >= 0.1.0"
requires "https://github.com/nitely/nim-regex >= 0.26.3"
