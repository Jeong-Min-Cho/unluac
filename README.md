# unluac - Lua Decompiler

> **Fork Notice**: This is a fork of the original unluac project from [SourceForge](https://sourceforge.net/p/unluac/hgcode/ci/default/tree/) with bug fixes and improvements.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](license.txt)

## Overview

**unluac** is a decompiler for Lua bytecode versions 5.0 through 5.5. It converts compiled Lua chunks back into readable Lua source code, making it useful for analyzing, debugging, and understanding Lua bytecode.

### Key Features

- ✅ **Multi-version Support**: Lua 5.0, 5.1, 5.2, 5.3, 5.4, and 5.5
- ✅ **Command-line Interface**: Simple and straightforward usage
- ✅ **Java-based**: Cross-platform compatibility
- ✅ **Debug Info Required**: Works with standard Lua compiler output (non-stripped chunks)

## Installation

**Requirements**: JDK 8 or higher, with `javac` and `java` on your `PATH` (a JRE alone is not enough). Building a standalone jar also needs `jar`.

Clone the repository:

```bash
git clone https://github.com/Jeong-Min-Cho/unluac.git
cd unluac
```

### Build a standalone jar

```bash
mkdir -p build/classes
javac -d build/classes -sourcepath src src/unluac/Main.java
jar cfm unluac.jar MANIFEST.MF -C build/classes .
java -jar unluac.jar input.luac -o output.lua
```

### Build and run from source

Use one command to compile the current sources and run the tool. From the repository root:

**Linux / macOS / Git Bash:**

```bash
bash ./unluac.sh "input.luac" -o "output.lua"
```

**Windows (Command Prompt or PowerShell):**

```powershell
.\unluac.bat "input.luac" -o "output.lua"
```

Each invocation cleans `build/classes`, compiles `Main.java` and its dependencies from `src`, and runs the fresh classes. If compilation fails, the tool does not run. All arguments and the exit code are passed through, and build commands do not add anything to stdout, so output redirection also works:

```bash
bash ./unluac.sh --disassemble "input.luac" > disassembly.txt
bash ./unluac.sh --typemap xlua.typemap "input.luac" -o "output.lua"
bash ./unluac.sh --version
```

After each Java edit, just rerun the same command. You can invoke the scripts by path from another directory; input/output paths remain relative to your working directory. Run invocations sequentially because they share the build directory.

## Usage

### Basic Usage

```bash
bash ./unluac.sh input.luac > output.lua
```

### Examples

**Decompile a Lua chunk:**

```bash
bash ./unluac.sh myfile.luac > myfile_decompiled.lua
```

**Decompile with custom opcode mapping** (for modified Lua VMs with shuffled opcodes):

```bash
bash ./unluac.sh --opmap opcode_map.txt myfile.luac > output.lua
```

An opcode map is a plain text file, one `.op <number> <name>` per line:

```
.op 0 getglobal
.op 1 settable
.op 2 getupval
# ... etc
```

**Disassemble instead of decompile:**

```bash
bash ./unluac.sh --disassemble myfile.luac
```

### Command-line Options

- `--assemble` - Assemble a disassembly listing (requires `--output`)
- `--disassemble` - Output disassembly instead of decompiled code
- `--annotate-source` - Add original source labels and function-definition line ranges as comments
- `--nodebug` - Ignore debugging information in the input file
- `--typemap <file>` - Use custom type mapping file (for modified Lua VMs with swapped constant types)
- `--opmap <file>` - Use custom opcode mapping file (for modified Lua VMs with shuffled opcodes)
- `--output <file>` / `-o <file>` - Write to `<file>` instead of standard output
- `--rawstring` - Copy string bytes directly to the output
- `--luaj` - Emulate Luaj's permissive parser
- `--help` - Show all options
- `--version` - Show version information

### Optional source annotations

```bash
bash ./unluac.sh --annotate-source input.luac -o output.lua
```

Or on Windows:

```powershell
.\unluac.bat --annotate-source input.luac -o output.lua
```

This adds a comment at the beginning of the main chunk and inside each emitted
function body, including anonymous functions:

```lua
function Example:run(value)
  -- Original source: "@scripts/example.lua"; definition lines 12-18
  return value
end
```

The annotations use the chunk's debug metadata, not the input filename or the
line numbers of the generated Lua. Missing source labels inherit from the
parent prototype; line ranges do not. Unknown labels or definition lines are
reported as `unavailable` (common for stripped chunks and synthetic wrappers).
If only a definition's start line is available, only that line is reported.

Source labels retain Lua's `@`/`=` markers and are quoted/escaped so embedded
newlines or control characters cannot turn a comment into executable Lua.
Labels can contain original machine paths or source text. These are comments
only: no statement-level source map or original formatting is reconstructed.
The flag does not change disassembly/assembly output and is off by default.
`--nodebug` still disables debug-based variable reconstruction; it does not
suppress explicitly requested source annotations.

> **Note**: This tool is intended for legitimate purposes such as debugging, learning, and analyzing Lua code. Please respect intellectual property rights and use responsibly.

## Requirements

- **Java**: JDK 8 or higher
- **Input**: Lua bytecode compiled with debug information (default for `luac`)
- **Supported Lua Versions**: 5.0, 5.1, 5.2, 5.3, 5.4, 5.5

> **Note**: The Lua compiler includes debugging information by default. If chunks are compiled with the `-s` flag (strip debug info), decompilation will not work properly.

## Compatibility

### Lua Version Support

| Lua Version | Support Level                  |
| ----------- | ------------------------------ |
| Lua 5.0     | ✅ Very good                   |
| Lua 5.1     | ✅ Very good                   |
| Lua 5.2     | ✅ Good                        |
| Lua 5.3     | ✅ Good                        |
| Lua 5.4     | ✅ Good (some goto edge cases) |
| Lua 5.5     | ✅ Good                        |

### Supported Variants

#### xLua (Tencent, used in Unity games)

xLua is Tencent's Lua 5.3 bridge for Unity, used widely in Chinese mobile games. It writes a modified header and swaps the integer/float constant type tags compared with standard Lua 5.3:

| Modification | Standard Lua 5.3 | xLua |
| --- | --- | --- |
| Integer constant type tag | 3 | 19 |
| Float constant type tag | 19 | 3 |
| Header (bytes 0–4) | `\x1bLua\x53` | Modified |

The steps below normalize the header and the constant tags; no patched build is required for those two differences. This workflow has not been verified against a real xLua chunk. Upvalue entries are read with the standard Lua 5.3 2-byte format — there is no xLua-specific upvalue parsing, so chunks with a different upvalue layout are not supported.

**Step 1 — Fix the header**

Replace the first 5 bytes of the `.luac` file with the standard Lua 5.3 header:

```python
STANDARD_LUA53_HEADER = b'\x1bLua\x53'

def fix_xlua_header(data: bytes) -> bytes:
    return STANDARD_LUA53_HEADER + data[5:]
```

**Step 2 — Create a typemap file** (`xlua.typemap`):

```
.type 3 integer
.type 19 float
```

**Step 3 — Decompile:**

```bash
bash ./unluac.sh --typemap xlua.typemap fixed.luac -o output.lua
```

### Known Limitations

- **Stripped Bytecode**: Cannot decompile chunks compiled with `-s` flag
- **Complex Gotos**: Lua 5.2+ code with heavy use of goto statements may not decompile perfectly
- **Custom Lua VMs**: Modified Lua implementations may require custom opcode or type mappings (see [Supported Variants](#supported-variants) for known working configurations)

## Changes in This Fork

- **Lua 5.5 support** ([#6](https://github.com/Jeong-Min-Cho/unluac/pull/6)): Lua 5.5 bytecode can be decompiled.
- **ArrayIndexOutOfBoundsException fix** ([#2](https://github.com/Jeong-Min-Cho/unluac/pull/2)): corrected the off-by-one register count for CALL/VARARG instructions with variable return values in `Decompiler.java` and added bounds checking in `Registers.java`.
- **IllegalStateException crash fix** ([#3](https://github.com/Jeong-Min-Cho/unluac/pull/3)).
- **Loop and break fixes** ([#11](https://github.com/Jeong-Min-Cho/unluac/issues/11)): nested breaks redirected through enclosing loops, Lua 5.5 repeat loops with captured locals, and Lua 5.5 integer constants.
- **`--annotate-source`** ([#10](https://github.com/Jeong-Min-Cho/unluac/pull/10)): optional original-source and definition-line comments; see [Optional source annotations](#optional-source-annotations).

## Credits

### Original Authors

- **tehtmi** - Main developer
- **Thomas Klaeger** - Added support for Lua 5.0
- **John Fowler** - Contributed closure fix patch

See [authors.txt](authors.txt) for complete attribution.

### This Fork

Bug fixes and improvements by contributors to this repository.

## Running Tests

The regression suite (`unluac.test.RunTests`) compiles each `test/src/*.lua` with reference
`luac` binaries, decompiles, recompiles, and compares bytecode. It expects `luac50`, `luac51`,
`luac514`, `luac52`, `luac53`, `luac54`, `luac548` and `luac55` on `PATH`;
`tools/build-luac.sh` downloads, verifies and builds them into `~/.local/bin`.
See the "Running tests" section of [AGENTS.md](AGENTS.md) for the exact command.

## License

MIT License - see [license.txt](license.txt) for details.

Copyright (c) 2011-2020 tehtmi
Portions Copyright (c) 2014 Thomas Klaeger

## Resources

- **Original Project**: [SourceForge - unluac](https://sourceforge.net/p/unluac/hgcode/ci/default/tree/)
- **Issue Tracker**: [GitHub Issues](https://github.com/Jeong-Min-Cho/unluac/issues) — report bugs and request features here
- **Lua Official Site**: [lua.org](https://www.lua.org/)
- **Lua Reference Manual**: [Lua 5.4 Reference](https://www.lua.org/manual/5.4/)

## Troubleshooting

- **Crash or exception during decompilation**: Make sure the chunk was compiled with debug information and that its Lua version is supported (5.0–5.5). For a modified Lua VM, try an opcode or type mapping file (see [Command-line Options](#command-line-options)).
- **Decompiled code looks wrong**: Complex goto control flow and compiler optimizations are known limitations (see [Known Limitations](#known-limitations)).
- **Still stuck**: Search the [issue tracker](https://github.com/Jeong-Min-Cho/unluac/issues) and open a new issue with the Lua version and a minimal bytecode sample.
