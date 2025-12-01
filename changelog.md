# Changelog

## 0.36.1

- 'slice' causes a fatal crash when slicing strings

## 0.36.0

- Page now (after ***much*** pain) has closures
- Lists literals now draw items from parent stacks (e.g. `1 2 3 [pop]` is now valid)

## 0.35.1

- 'ge' was misnamed as 'gt'

## 0.35.0

- Added the 'slice' builtin operator
- 'get' now works with strings
- Several types now format slightly differently

## 0.34.1

- Updated how 'psymbols' and 'prsymbols' show the symbol list
- (Fix) dot-accessing caused very serious scope issues

## 0.34.0

- Added the 'sqrt', 'neg', and 'undef?' builtin operators
- (Fix) 'undef' did nothing

## 0.33.1

- (Fix) procedure execution from dot notation didn't enter the scope of the accessed dictionaries.

## 0.33.0

- Added the 'alpha?', 'digit?', 'alphadigit?', 'sb-init', 'sb-addstr', 'sb-addbyte', and 'sb-build' operators to the 'strings' internal library

## 0.32.0

- Page now has dot notation for accessing items inside of dictionaries conveniently
- The '.' builtin operator has been removed
- (Fix) unterminated array and procedure literals didn't cause an error
- (Fix) point three of the previous changelog wasn't applied to 'readf' and 'writef'
- Edited the 'json' example to use dot notation
- Added the 'nest' example

## 0.31.0

- File imports are now cached
- Relative import and 'f-open' paths are now relative to the executed file's directory, not the shell's directory
- Added the '2item?', '<<', '>>', and 'undef' builtin operators
- Added the '>cmd' and 'cmd' operators to the 'os' internal library
- Added the 'f-eof' and 'f-readbyte' operators to the 'io' internal library
- Added the 'json' internal library with the 'decodes', 'decodef', 'encodes', and 'encodef' operators

## 0.30.12

- The help messages have been updated as they contained outdated information
- The comments in the 'fib' example have been updated as Page is no longer a PostScript implementation
- Updated the docstrings of many builtin operators

## 0.30.11

- (Fix) 'f-write' didn't return the number of bytes written
- (Fix) 'stdout' and 'stderr' both pointed to stdin
- Removed some WASM target remants
- The REPL now saves everything, even if a fatal error occurs
- Added the 'item?', '-rot', 'band', 'bor', 'xor', 'bnot', 'inf', '-inf', 'round', 'floor', 'ceil', 'not', 'load?', and 'dcopy' builtin operators
- Added the 'exe', 'file', 'argv', 'env>', 'env?>', and '>env' operators to the 'os' internal library

## 0.29.0

- Added the 'somefrom' builtin symbol

## 0.28.0

- Type unions are no longer stored as sets
- Renamed src/std/testing.nps to src/std/testing.pg
- Added the 'os' internal library with the 'stderr', 'stdout', and 'stdin' symbols
- Added the 'io' internal library with the 'f-write', 'f-open', 'f-close', and 'f-read' operators
- Added the ExtItem datatype, which represents a pointer to abstract data

## 0.27.1

- (Fix) tString wasn't included in the tAny set
- (Fix) Literal-bound procedures (created via 'bind') functioned incorrectly

## 0.27.0

- Page's type checking system now uses sets instead of direct bitwise comparison

## 0.26.0

- Added the 'upper' and 'lower' operators to the 'strings' builtin module
- The 'http' module can now be disabled at compile-time using the 'nohttp' symbol
- Added the 'target' and 'help' subcommands to build.nims

## 0.25.0

- Added the 'null?', 'defer', 'throw', 'try', and 'trycatch' builtin operators

## 0.24.1

- NPScript has been renamed to "Page"
- All documentation for builtins has been moved into docstrings
- The build system now uses NimScript
- 'import' now uses `/` intead of `.` as a path separator
- The project dependancies are now stored locally

## 0.23.0

- (Fix) Symbols were being resolved from the oldest dict to the newest dict instead of the other way around
- 'symbols' has been replaced with 'psymbols', 'symbols' now operates differently
- 'langver' has been renamed to 'version'
- Added the 'product', 'bind', 'rsymbols', 'psymbols', and 'prsymbols' builtin operators
- 'get' and 'put' now support negative indexes
- Procedures can now be 'literal', meaning symbols inside of them are pre-resolved

## 0.22.0

- NPScript values are now represented by a tagged union instead of a class object
- The 'Number' type is now separated into 'Integer' and 'Real' types
- The 'Function' type has been renamed to 'Procedure'
- 'import' now uses `.` intead of `/` as a path separator

## 0.21.2

- (Fix) builtin comparison operators weren't getting added to the dictionary correctly
- "./.pkg" is now an import search path
- The 'huhs?' builtin operator has been renamed to 'docof'
- Added the 'setdoc' builtin operator
- Added the 'replace' operator to the 'strings' internal library
- Composite functions now show their contents with debug like GhostScript

## 0.20.1

- Removed an unused missing library from npscript.nim
- Streamlined the dependancy installation process
- Added a todo list and contribution guidelines
- Altered the builtin operator 'sts' to be more in line with the standard PostScript equivalent
- Changed a comment in the 'fib' example, as it contained outdated information

## 0.20.0

- Added the 'http' internal library with the 'init', 'req', 'get', 'post', 'put', and 'delete' operators
- Function argument type errors will now show parameter
- (Fix) using math operators on a number and a non-number caused infinite recursion
- Added the 'filter' example
- Altered the documentation of the 'add', 'sub', 'mul', 'div', 'mod', 'exp', 'length', and 'sts' operators

## 0.19.5

- (Fix) the basic help message was misformatted
- NPScript now uses https://github.com/nitely/nim-regex instead of std/re for regex to solve dynamic linking issues

## 0.19.4

- The musl targets are now statically linked
- build.sh now has a help message

## 0.19.3

- Switched from using an internal library to https://github.com/voidwyrm-2/nargparse for argument parsing

## 0.19.2

- Revamped the message printed by the 'help' function with tips from someone
- Added the 'exthelp' and 'pi' builtin functions
- Added the '-e/--exec' flag
- The help message is split into shorted and extended versions
- Non-function builtin symbols and non-native builtin functions now have docstrings

## 0.18.3

- NPScript data objects now have a 'doc' field attached
- Added the 'help', 'huhs?', 'huhl?', 'huhp?', and 'huh?' builtin functions
- The builtin symbols 'langver', 'null', 'false', and 'true' now have docstrings

## 0.17.2

- (Fix) The global logger wasn't being initialized when '-log' wasn't passed, causing nil accesses

## 0.17.1

- (Fix) Flags created with 'argparse.opt' didn't collect their arguments
- (Fix) Functions like 'dict' and 'list' which required a whole number as an argument would cause SIGINT (illegal operation/illegal instruction) on x86 systems
- Added the 'log' flag and debug logging
- Altered the help message of the '--fstd/--force-std'

## 0.16.4

- Edited the signatures of many builtin functions
- Edited the documentation of the 'sprintf', 'if', 'ifelse', 'dict', 'false', and 'true' builtin symbols
- Added the 'null' type and builtin symbol
- Added the 'array', 'get', 'put', and 'length' builtin functions
- Changed the formatting in the 'range' example
- Added the 'fib' and 'fizzbuzz' examples

## 0.15.0

- The 'type' builtin function now returns a symbol

## 0.14.0

- The 'import' builtin function now has a set of search paths (listed in its documentation)
- Added the 'importdef', '.', and 'sts' builtin symbols
- Renamed the 'cvi' function to 'stn'
- The 'sprintf' function now preallocates part of the final result string
- Updated the documentation of 'readf' and 'ifelse'

## 0.13.1

- '.' was parsed as '0'
- Builtins are no longer compile-time defined as it made them inaccesible at runtime
- The builtins are now copied on each interpreter instantiation; previously the original object was passed, and this allowed changes to the dictionary to effect imported files

## 0.13.0

- Renamed src/libraries -> src/builtinlibs
- The builtin libraries are now created at compile time
- 'inf', '-inf', and 'nan' can now be used to create the respective number values
- Updated the documentation of 'split' (from 'strings')

## 0.12.8

- The String and NpsList types now use 64-bit integers for their lengths
- Renamed String::txt -> String::ptr
- Renamed NpsList::arr -> NpsList::ptr
- NpsDict now has the `uint64_t len(void)` method
- The NpsValue::getBool method now returns Bool instead of uint32_t

## 0.12.7

- A message listing the version, the os/arch that's being compiled on, the os/arch that's being compiled for, and the mode it's being compiled in is now printed
- The internal language version is now read from the nimble file
- If the string 'import' takes as its argument doesn't have an extension
- Only forward-slashes are allowed in 'import' paths, but forward-slashes are replaced with back-slashes on Windows
- Added the --fstd/--force-std flag
- The standard library (found in src/std/ and its subfolders) is now embedded inside of the executable at compile-time, and is written to ~/.npscript/std/ when the executable is first run, if that folder doesn't exist, or if --force-std is passed
- A C header ('npscript.h', found in src/data) is now embedded inside of the executable at compile-time, which will be used for C FFI in the future; this header is written to ~/.npscript/include when the executable is first run or if that folder doesn't exist
- The standard library has one module, 'testing'

## 0.11.1

- (Fix) 'or' was misnamed as 'and'

## 0.11.0

- Added the 'and' and 'or' builtin symbols

## 0.10.4

- Rephrased the documentation for several builtin symbols
- Added the 'idiv', 'mod', 'exp', 'print', 'sprintf', 'from', and 'allfrom' builtin symbols
- The dictionary datatype now debug formats to '-dict-'
- Updated the 'math' test to add cases for 'idiv', 'mod', and 'exp'

## 0.9.0

- NPScript now creates a .npscript folder in the home directory
- The REPL now has a persistent history

## 0.8.4

- Updated code styling and formatting

## 0.8.3

- NPScript can now compile and run on wasm32 targets, but reading files doesn't work currently
- An internal argument parsing library (argparse) is now used instead of std/optparse
- Errors are now printed to stderr instead of stdout

## 0.7.0

- Added the 'printf' builtin symbol

## 0.6.1

- Updated the 'import' documentation

## 0.6.0

- Added the 'import' buitlin symbol

## 0.5.13

- (Fix) Nested loops conflicted with each other's states

## 0.5.12

- Added the 'cvi' builtin symbol

## 0.5.11

- (Fix) 'exit' could not be used inside of 'forall'

## 0.5.10

- Added the 'split' symbol to '~strings'

## 0.5.9

- (Fix) Escape squences were getting read as multiple characters

## 0.5.8

- Added support for escape sequences

## 0.5.7

- Added the 'readf' and 'writef' builtin symbols

## 0.5.6

- (Fix) The lexer would flag '!', '"', '#', '$', '%', and '~' as illegal characters
- Added the 'scoped' and 'symbols' builtin symbols
- Added the '~strings' internal library, containing the symbol 'chars'

## 0.5.5

- Added the 'forall' builtin

## 0.5.4

- Rewrote much of the documention for the builtin functions
- Added the 'type', 'quitn', 'gt', 'ge', 'lt', 'le', 'ifelse', and 'for' builtins

## 0.5.2

- (Fix) The error that using 'exit' outside of a loop caused didn't have a stacktrace

## 0.5.1

- Updated REPL header

## 0.5.0

- Added the '-h|--help' flag
- Implemented the REPL

## 0.4.3

- Added the '-v|--version' flag

## 0.4.2

- Added the dict datatype
- Added the 'eq', 'ne', 'if', 'dict', 'begin', 'end' builtins
- Updated the 'range' example

## 0.4.1

- Added the dict datatype
- Added the 'dict', 'begin', and 'end' builtins

## 0.4.0

- Added the bool datatype
- Added the 'quit', 'exit', 'true', 'false', 'pop', 'dup', 'exch', 'add', 'sub', 'mul', 'div', 'stack', 'pstack', 'loop', 'def', and 'load' builtins

## 0.3.4

- Slightly refactored how functions are represented
- Refactored the builtins file to allow for ease of writing

## 0.3.3

- Added support for list and function literals
- Added the list datatype
- Refactored the NpsError object
- Added the 'exec' builtin
