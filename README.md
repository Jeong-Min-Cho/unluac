# unluac - Lua Decompiler

> **Fork Notice**: This is a fork of the original unluac project from [SourceForge](https://sourceforge.net/p/unluac/hgcode/ci/default/tree/) with bug fixes and improvements.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

## Overview

**unluac** is a decompiler for Lua bytecode versions 5.0 through 5.4. It converts compiled Lua chunks back into readable Lua source code, making it useful for analyzing, debugging, and understanding Lua bytecode.

### Key Features

- ✅ **Multi-version Support**: Lua 5.0, 5.1, 5.2, 5.3, and 5.4
- ✅ **Command-line Interface**: Simple and straightforward usage
- ✅ **Java-based**: Cross-platform compatibility
- ✅ **Debug Info Required**: Works with standard Lua compiler output (non-stripped chunks)

## Installation

### Download

Download the latest JAR file from the official [SourceForge](https://sourceforge.net/projects/unluac/) page, or use the pre-built `unluac.jar`.

### Build from Source

**Requirements**: JDK 8 or higher

```bash
# Clone the repository
git clone https://github.com/Jeong-Min-Cho/unluac.git
cd unluac

# Compile
cd src
javac -d ../build unluac/Main.java

# Create JAR
cd ../build
jar cfm ../unluac.jar ../MANIFEST.MF unluac/
```

## Usage

### Basic Usage

```bash
java -jar unluac.jar <input.luac> > output.lua
```

### Examples

**Decompile a Lua chunk:**

```bash
java -jar unluac.jar myfile.luac > myfile_decompiled.lua
```

**Decompile with custom opcode mapping** (for custom Lua implementations like xlua):

```bash
java -jar unluac.jar --opmap opcode_map.txt myfile.luac > output.lua
```

**Disassemble instead of decompile:**

```bash
java -jar unluac.jar --disassemble myfile.luac
```

### Command-line Options

- `--opmap <file>` - Use custom opcode mapping file (for modified Lua VMs)
- `--disassemble` - Output disassembly instead of decompiled code
- `--version` - Show version information

## Requirements

- **Java**: JRE/JDK 8 or higher
- **Input**: Lua bytecode compiled with debug information (default for `luac`)
- **Supported Lua Versions**: 5.0, 5.1, 5.2, 5.3, 5.4

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

### Known Limitations

- **Stripped Bytecode**: Cannot decompile chunks compiled with `-s` flag
- **Complex Gotos**: Lua 5.2+ code with heavy use of goto statements may not decompile perfectly
- **Custom Lua VMs**: Modified Lua implementations may require custom opcode mappings

## Changes in This Fork

This fork includes critical bug fixes not present in the original version:

### Fixed: ArrayIndexOutOfBoundsException (Critical)

**Problem**: Original unluac crashed when decompiling valid Lua bytecode containing CALL or VARARG instructions with variable return values at register boundaries.

**Solution**:

- Fixed off-by-one error in register count calculation in `Decompiler.java`
- Added defensive bounds checking in `Registers.java`

**Impact**:

- Fixes crashes on valid Lua bytecode
- Improves compatibility with custom Lua implementations

## Credits

### Original Authors

- **tehtmi** - Main developer
- **Thomas Klaeger** - Added support for Lua 5.0
- **John Fowler** - Contributed closure fix patch

See [authors.txt](authors.txt) for complete attribution.

### This Fork

Bug fixes and improvements by contributors to this repository.

### Running Tests

If you have `luac` installed:

```bash
# Compile test files and run decompiler
cd test/src
luac -o ../compiled/test.luac test.lua
java -jar ../../unluac.jar ../compiled/test.luac
```

## License

MIT License - see [license.txt](license.txt) for details.

Copyright (c) 2011-2020 tehtmi
Portions Copyright (c) 2014 Thomas Klaeger

## Resources

- **Original Project**: [SourceForge - unluac](https://sourceforge.net/p/unluac/hgcode/ci/default/tree/)
- **Lua Official Site**: [lua.org](https://www.lua.org/)
- **Lua Reference Manual**: [Lua 5.4 Reference](https://www.lua.org/manual/5.4/)

## Troubleshooting

### "Exception in thread..." errors

If you encounter `ArrayIndexOutOfBoundsException`, `NullPointerException`, or similar errors:

1. **Use this fork** - The original version has known bugs that are fixed here
2. **Check debug info** - Ensure your `.luac` file was compiled with debug information
3. **Verify Lua version** - Make sure the bytecode version is supported (5.0-5.4)
4. **Custom VM?** - If using a modified Lua VM, you may need an opcode mapping file

### Decompiled code doesn't run

This can happen due to:

- **Control flow complexity** - Very complex goto statements in Lua 5.2+
- **Bytecode optimization** - Some compiler optimizations may not decompile perfectly
- **Custom implementations** - Non-standard Lua VMs may have quirks

## Examples

### Example 1: Basic Decompilation

```lua
-- original.lua
local function greet(name)
    return "Hello, " .. name .. "!"
end
print(greet("World"))
```

```bash
# Compile
luac -o original.luac original.lua

# Decompile
java -jar unluac.jar original.luac > decompiled.lua
```

### Example 2: Working with Custom Lua VMs (xlua)

For modified Lua implementations with shuffled opcodes:

1. Create opcode mapping file:

```
.op 0 getglobal
.op 1 settable
.op 2 getupval
.op 3 setglobal
.op 4 return
.op 5 tforloop
.op 6 loadk
# ... etc
```

2. Decompile with mapping:

```bash
java -jar unluac.jar --opmap opcodes.txt custom.luac > output.lua
```

**Note**: This tool is intended for legitimate purposes such as debugging, learning, and analyzing Lua code. Please respect intellectual property rights and use responsibly.
