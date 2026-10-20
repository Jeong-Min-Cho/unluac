# Working on unluac

- Implementation sources are under `src/unluac/`.
- After editing Java sources, use `bash ./unluac.sh [arguments]` (Bash) or `.\unluac.bat [arguments]` (Windows). Each invocation cleans `build/classes`, recompiles the application from source, and runs it only if compilation succeeds. Requires a JDK with `javac` and `java` on `PATH`.
- Example: `bash ./unluac.sh input.luac -o output.lua`.
- Smoke check: `bash ./unluac.sh --version` (or `.\unluac.bat --version`). This checks compilation and startup, not decompilation correctness; also rerun the relevant Lua bytecode reproducer after a change.
- All tool arguments are forwarded unchanged. Input/output paths are relative to the caller's working directory. Exit codes propagate, and stdout contains only tool output, so redirection works.
- The two scripts share `build/classes`; run them sequentially, not concurrently.
