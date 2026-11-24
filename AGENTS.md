# Working on unluac

- Implementation sources are under `src/unluac/`.
- After editing Java sources, use `bash ./unluac.sh [arguments]` (Bash) or `.\unluac.bat [arguments]` (Windows). Each invocation cleans `build/classes`, recompiles the application from source, and runs it only if compilation succeeds. Requires a JDK with `javac` and `java` on `PATH`.
- Example: `bash ./unluac.sh input.luac -o output.lua`.
- Smoke check: `bash ./unluac.sh --version` (or `.\unluac.bat --version`). This checks compilation and startup, not decompilation correctness; also rerun the relevant Lua bytecode reproducer after a change.
- All tool arguments are forwarded unchanged. Input/output paths are relative to the caller's working directory. Exit codes propagate, and stdout contains only tool output, so redirection works.
- The two scripts share `build/classes`; run them sequentially, not concurrently.

## Running tests

- Reference compilers: the harness runs `luac50`, `luac51`, `luac514`, `luac52`, `luac53`, `luac54`, `luac548` and `luac55` from `PATH` (`luac55.exe` etc. on Windows; `-Dluac55=C:\path\luac` overrides one, and `.exe` is appended automatically on Windows, so leave it off). A missing compiler makes its tests *skip*, not fail, and an all-skipped run still exits 0, so check the summary line.
  - Linux: `bash tools/build-luac.sh` downloads the official tarballs into `~/.cache/unluac-lua`, verifies their SHA-256 sums, and installs the binaries into `~/.local/bin`. Idempotent; pass names to build a subset, `FORCE=1` to rebuild. Needs `build-essential`, `curl` and `libreadline-dev`.
  - Windows: no build script yet; put your own `luacXX.exe` builds on `PATH`, or run the suite from WSL.
- Full suite, from the repository root (uses `./test/src` and `./test/working`):

  ```bash
  rm -rf build/classes && mkdir -p build/classes && javac -d build/classes -sourcepath src src/unluac/Main.java src/unluac/test/RunTests.java && java -cp build/classes unluac.test.RunTests
  ```

  Windows (Command Prompt):

  ```bat
  (if exist build\classes rmdir /s /q build\classes) & mkdir build\classes && javac -d build\classes -sourcepath src src\unluac\Main.java src\unluac\test\RunTests.java && java -cp build\classes unluac.test.RunTests
  ```

  Prints one line per Lua version (`.` = pass, `,` = skipped, `!` = failed) followed by a list of failures and skips; exits non-zero if anything failed. Shares `build/classes` with `unluac.sh`/`unluac.bat`, so don't run them concurrently.
- Fuzz tests: same command with `RunFuzzTests` in place of `RunTests` (optional argument: mutations per chunk, default 300). They check that truncated or corrupted chunks fail with `MalformedChunkException`; a parser change that lets another exception escape shows up here.
- New tests: add `test/src/<name>.lua` and register it in `src/unluac/test/TestFiles.java`. A hex prefix (e.g. `55_`) restricts the test to that Lua version and later. Keep harness paths forward-slashed (`./test/src/`): Java and `luac` accept `/` on Windows, while `\` is an ordinary filename character on Linux.
