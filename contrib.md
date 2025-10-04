# Contributing

## Code of conduct

Basically, be polite to everyone and use common sense.

## Repository structure

- `examples/` - the language examples; just various snippets I wrote to show off the language.
- `out/`, `dist/` - the binary output folders, these contains the resulting executables and the zip files created from them, respectively; these should **always** be gitignored.
- `src/builtins.nim` - the builtin functions that are always available without importing.
- `src/builtinlibs/` - the internal libraries that come built into Page, such as `strings` and `http`.
- `src/valueimpls` - the implementations for the individual value objects, which get `include`'d into `src/values.nim`; this folder may get removed in the future, see item No. 1 of [todo.md](/todo.md)
- `src/std/` - the parts of the standard library implementated in Page that are written to `~/.page/std/`.
- `src/data/` - miscellaneous data that gets included into the binary at compile-time.

## Code styling

Really, just try to follow the styling of the rest of the repo, it's basically the same as Nim's [official style guide](https://nim-lang.org/docs/nep1.html).

Differences and/or specifics are:

- Imports, type definitions, and functions should be separated by two lines instead of one. See [parser.nim](/src/parser.nim) for an example.

- If an import is from a different namespace, it should be prefixed with `pkg/` and `std/`, respectively. See [builtins.nim](/src/builtins.nim) for an example.

- Single item imports/exports should be on a single line. See [builtins.nim](/src/builtins.nim) for an example.

- Multi-item imports/exports should be expanded across multiple lines. See [builtins.nim](/src/builtins.nim) for an example.

- Multi-item imports that come from a different namespace should be expanded across multiple lines with `[]` (brackets). See [builtins.nim](/src/builtins.nim) for an example.
