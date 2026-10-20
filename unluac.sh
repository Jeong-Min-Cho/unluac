#!/usr/bin/env bash
# Compile the current sources and run with the supplied arguments.
set -euo pipefail

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
classes="$root/build/classes"

rm -rf -- "$classes"
mkdir -p -- "$classes"
javac -d "$classes" -sourcepath "$root/src" "$root/src/unluac/Main.java"
exec java -cp "$classes" unluac.Main "$@"
