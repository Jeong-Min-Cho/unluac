# Changelog

All notable changes to this fork are listed here. Versions follow [Semantic Versioning](https://semver.org/). The fork started from upstream unluac 1.2.3.530 (October 2025); upstream's own history is on [SourceForge](https://sourceforge.net/p/unluac/hgcode/).

## [1.3.0] - Unreleased

First release of the fork.

### Added

- Lua 5.5 support: the 5.5 header, string and upvalue formats, named varargs and the 5.5 opcode set.
- `--annotate-source`, which adds a comment with each function's original source name and line range.
- xLua documentation: decompiling its Lua 5.3 bytecode with a header fix and `--typemap`.
- `unluac.sh` and `unluac.bat` wrapper scripts, and a jar manifest so `java -jar unluac.jar` works.
- `tools/build-luac.sh`, which builds the reference `luac` compilers the test suite needs.
- GitHub Actions CI that runs the full suite against every supported Lua version.

### Fixed

- `ArrayIndexOutOfBoundsException` on `CALL` and `VARARG` instructions with a variable number of arguments or results.
- `IllegalStateException` on a `LOADKX` that isn't followed by `EXTRAARG`.
- Nested loops and breaks dropped or misplaced when a `break` jumps through an enclosing loop's back edge.
- Lua 5.5 integer constants decoded incorrectly.
- Lua 5.5 `repeat` loops with captured locals not recognized.
- Lua 5.0 while loops whose entry jump was threaded by the compiler.
- Unmapped opcodes with `--opmap` crashed instead of reporting `unmapped opcode N`.

### Changed

- `--version` reports the fork's own version (1.3.0) instead of upstream's build number.

[1.3.0]: https://github.com/Jeong-Min-Cho/unluac/releases/tag/v1.3.0
