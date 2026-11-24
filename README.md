# unluac

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](license.txt)

unluac decompiles Lua bytecode back into Lua source. It reads chunks produced by `luac` for Lua 5.0 through 5.5 and can also disassemble them or assemble a disassembly listing back into bytecode.

This is a fork of [tehtmi's unluac](https://sourceforge.net/p/unluac/hgcode/ci/default/tree/) on SourceForge. It supports Lua 5.5, fixes several crashes and control-flow bugs, and runs the regression suite against real `luac` builds for every supported version. See [What this fork changes](#what-this-fork-changes).

```console
$ luac -o greet.luac greet.lua
$ bash ./unluac.sh greet.luac
local function greet(n)
  return "Hello, " .. n
end

print(greet("World"))
```

## Getting started

### Prebuilt jar

Download `unluac-<version>.jar` from the [Releases page](https://github.com/Jeong-Min-Cho/unluac/releases) and run it with Java 8 or newer:

```bash
java -jar unluac-1.3.0.jar input.luac -o output.lua
```

Each release also has a `SHA256SUMS` file for checking the download with `sha256sum -c SHA256SUMS`.

### From source

You need a JDK 8 or newer with `javac` and `java` on your `PATH`. A JRE alone can't compile the sources.

Clone the repository and run the wrapper script from its root:

```bash
git clone https://github.com/Jeong-Min-Cho/unluac.git
cd unluac
bash ./unluac.sh input.luac -o output.lua
```

On Windows, use `.\unluac.bat input.luac -o output.lua`.

The scripts clean `build/classes`, compile from `src/`, and run the result. They stop if compilation fails, pass every argument and the exit code through, and print nothing of their own to stdout, so redirection works. You can call them by path from another directory; input and output paths stay relative to where you are. Two invocations share the build directory, so don't run them at the same time.

To build a standalone jar yourself:

```bash
mkdir -p build/classes
javac --release 8 -d build/classes -sourcepath src src/unluac/Main.java
jar cfm unluac.jar MANIFEST.MF -C build/classes .
java -jar unluac.jar input.luac -o output.lua
```

## Usage

```
java -jar unluac.jar [options] <file>
bash ./unluac.sh [options] <file>
```

Without `-o`, the decompiled source goes to stdout.

| Option | What it does |
| --- | --- |
| `-o`, `--output <file>` | Write to `<file>` instead of stdout |
| `--disassemble` | Print a disassembly listing instead of Lua source |
| `--assemble` | Assemble a disassembly listing into bytecode |
| `--typemap <file>` | Remap constant type tags, for VMs that changed them |
| `--opmap <file>` | Remap opcode numbers, for VMs that shuffled them |
| `--annotate-source` | Add comments with each function's original source name and line range |
| `--nodebug` | Ignore debug information in the input |
| `--rawstring` | Copy string bytes to the output unchanged |
| `--luaj` | Accept negative counts and lengths in the chunk, as Luaj's loader does |
| `--help` | Show the option list |
| `--version` | Print the version |

Debug information gives unluac local variable names and scopes. `luac` keeps it by default. Chunks compiled with `luac -s` decompile much less reliably.

### Source annotations

`--annotate-source` adds a comment to the main chunk and to every function body, anonymous functions included:

```lua
function Example:run(value)
  -- Original source: "@scripts/example.lua"; definition lines 12-18
  return value
end
```

The values come from the chunk's debug metadata, not from the input filename or the generated file's line numbers. A function without its own source label inherits its parent's; line ranges are never inherited. Anything missing prints as `unavailable`, which is normal for stripped chunks and synthetic wrappers. If only the start line is known, only the start line is shown.

Labels keep Lua's `@` and `=` prefixes and are quoted and escaped, so a newline or control character in a label can't break out of the comment. Labels may contain paths from the machine that compiled the chunk. The flag only adds comments: it doesn't restore original formatting or map individual statements. It has no effect on `--disassemble` or `--assemble`, and `--nodebug` doesn't turn it off.

## Lua versions

| Version | Status |
| --- | --- |
| 5.0, 5.1 | Very good |
| 5.2, 5.3 | Good |
| 5.4 | Good; some `goto` edge cases |
| 5.5 | Supported |

Code that uses `goto` heavily (5.2 and later) is the most likely to come out wrong or not at all.

## Modified Lua VMs

Some games ship a patched Lua VM. If the patch only renumbers constant type tags or opcodes, a map file passed with `--typemap` or `--opmap` is enough.

A map replaces the built-in table instead of patching it, so it has to list every tag or opcode the chunk uses. Decompiling fails with `unmapped type code N` or `unmapped opcode N` if one is missing. An incomplete opcode map still works with `--disassemble`, which prints unmapped opcodes as `opNN`; that helps when working out a shuffled map.

A type map has one `.type` line per tag. The names are `nil`, `boolean`, `false`, `true`, `number`, `float`, `integer`, `string`, `short_string` and `long_string`; which ones apply depends on the Lua version. Stock Lua 5.3 would be:

```
.type 0 nil
.type 1 boolean
.type 3 float
.type 19 integer
.type 4 short_string
.type 20 long_string
```

An opcode map has one `.op` line per opcode, using the lowercase names that `--disassemble` prints for that Lua version:

```
.op 0 move
.op 1 loadk
.op 2 loadkx
# ...one line for every opcode
```

### xLua

[xLua](https://github.com/Tencent/xLua), Tencent's Lua binding for Unity, embeds Lua 5.3. Stock xLua writes standard Lua 5.3 bytecode, which unluac reads as is.

Some games patch xLua further, typically changing the signature and swapping the integer and float type tags (3 and 19). They don't shuffle opcodes, so a type map is enough. For that variant:

1. Replace the first five bytes with the stock Lua 5.3 signature, `\x1bLua\x53`:

   ```python
   with open("input.luac", "rb") as f:
       data = f.read()
   with open("fixed.luac", "wb") as f:
       f.write(b"\x1bLua\x53" + data[5:])
   ```

2. Save this as `xlua.typemap`. It's the stock 5.3 map with 3 and 19 swapped:

   ```
   .type 0 nil
   .type 1 boolean
   .type 3 integer
   .type 19 float
   .type 4 short_string
   .type 20 long_string
   ```

3. Run:

   ```bash
   bash ./unluac.sh --typemap xlua.typemap fixed.luac -o output.lua
   ```

## Running the tests

The suite in `src/unluac/test` compiles each file in `test/src` with a reference `luac`, decompiles it, recompiles the output, and checks that the bytecode matches. It looks for `luac50`, `luac51`, `luac514`, `luac52`, `luac53`, `luac54`, `luac548` and `luac55` on `PATH`. On Linux, `bash tools/build-luac.sh` downloads the official Lua sources, checks their SHA-256 sums, and installs those binaries into `~/.local/bin`.

```bash
rm -rf build/classes && mkdir -p build/classes \
  && javac -d build/classes -sourcepath src src/unluac/Main.java src/unluac/test/RunTests.java \
  && java -cp build/classes unluac.test.RunTests
```

A version whose compiler is missing is skipped rather than failed, and a run where everything was skipped still exits 0, so read the summary.

`unluac.test.RunFuzzTests` truncates and corrupts chunks from the same compilers and checks that each one gets a clean error rather than an uncaught exception. Run it the same way, with `RunFuzzTests.java` in place of `RunTests.java`. An optional argument sets the number of random mutations per chunk (default 300). [AGENTS.md](AGENTS.md) has the Windows command and how to add a test.

## What this fork changes

Compared with the upstream code the fork started from (1.2.3.530, October 2025):

- Lua 5.5 support: the 5.5 header, string and upvalue formats, named varargs, the 5.5 opcode set, and correct decoding of integer constants.
- Fixed an `ArrayIndexOutOfBoundsException` caused by an off-by-one register count on `CALL` and `VARARG` instructions with a variable number of arguments or results.
- Fixed an `IllegalStateException` on a `LOADKX` that isn't followed by `EXTRAARG`.
- Fixed nested loops and breaks that were dropped or misplaced when a `break` jumps through an enclosing loop's back edge, and Lua 5.5 `repeat` loops with captured locals.
- Added `--annotate-source`.
- Added `unluac.sh` and `unluac.bat`, a jar manifest, and `tools/build-luac.sh` for the test compilers.

[CHANGELOG.md](CHANGELOG.md) lists the changes in each release.

Bugs and feature requests go to the [issue tracker](https://github.com/Jeong-Min-Cho/unluac/issues). Attaching the `.luac` file, or the source and the `luac` version that produced it, makes a report much easier to act on.

## Credits and license

unluac was written by tehtmi. Thomas Klaeger added Lua 5.0 support and John Fowler contributed a closure fix; see [authors.txt](authors.txt).

Released under the MIT License; see [license.txt](license.txt).
Copyright (c) 2011-2020 tehtmi. Portions copyright (c) 2014 Thomas Klaeger.

Please use unluac on code you have the right to inspect.
