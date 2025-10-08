# TODO

- [x] Convert the current value system into a tagged union (native `Function` values need to be passed a `pointer` that should be converted into `State` in `addF` to avoid a circular dependancy)
- [x] Move `addF` definition doccomments into docstrings in builtins.nim
- [x] `trycatch` and `try` operators
- [x] `defer` operator
- [ ] Unit tests, in both Nim and Page
- [ ] `os` internal library
- [ ] `regex` internal library
- [ ] HTTP web framework internal library
- [ ] More examples
- [ ] C interop (very low priority)
