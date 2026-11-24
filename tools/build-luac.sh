#!/usr/bin/env bash
# Download, verify, and build the reference Lua compilers used by the test
# harness (src/unluac/test), installing only the luac binaries into
# ~/.local/bin under the names the harness expects.
#
# Idempotent: versions whose installed binary already reports the expected
# version are skipped; tarballs and build trees are cached.
#
# Environment overrides:
#   LUAC_CACHE_DIR  (default: ~/.cache/unluac-lua)
#   LUAC_BIN_DIR    (default: ~/.local/bin)
#   FORCE=1         rebuild and reinstall everything
#
# Usage: tools/build-luac.sh [name ...]   e.g. tools/build-luac.sh luac55
set -euo pipefail

cache="${LUAC_CACHE_DIR:-$HOME/.cache/unluac-lua}"
bindir="${LUAC_BIN_DIR:-$HOME/.local/bin}"
base_url="https://www.lua.org/ftp"

# name  version  sha256 (as published at https://www.lua.org/ftp/)
targets=(
  "luac50  5.0.3 1193a61b0e08acaa6eee0eecf29709179ee49c71baebc59b682a25c3b5a45671"
  "luac51  5.1.5 2640fc56a795f29d28ef15e13c34a47e223960b0240e8cb0a82d9b0738695333"
  "luac514 5.1.4 b038e225eaf2a5b57c9bcc35cd13aa8c6c8288ef493d52970c9545074098af3a"
  "luac52  5.2.4 b9e2e4aad6789b3b63a056d442f7b39f0ecfca3ae0f1fc0ae4e9614401b69f4b"
  "luac53  5.3.6 fc5fd69bb8736323f026672b1b7235da613d7177e72558893a0bdcd320466d60"
  "luac54  5.4.9 2335b6c582a52654f94612bf10d2f4672805d05329aa6568b1d8cd9e5c6fb8e6"
  "luac548 5.4.8 4f18ddae154e793e46eeab727c59ef1c0c0c2b744e7b94219710d76f530629ae"
  "luac55  5.5.1 1c4b4068d67061f2a2231ad2b5422e77acea1487ea9890f6320af614f4373dce"
)

log() { printf '==> %s\n' "$*" >&2; }

installed_ok() { # name version
  local bin="$bindir/$1"
  [[ -x "$bin" ]] && "$bin" -v 2>&1 | grep -q "Lua $2\b"
}

fetch() { # version sha256 -> prints tarball path
  local ver="$1" sum="$2" tgz="$cache/lua-$1.tar.gz"
  if [[ ! -f "$tgz" ]] || ! echo "$sum  $tgz" | sha256sum -c --status; then
    log "downloading lua-$ver.tar.gz"
    curl -fsSL --retry 3 -o "$tgz.part" "$base_url/lua-$ver.tar.gz"
    if ! echo "$sum  $tgz.part" | sha256sum -c --status; then
      rm -f -- "$tgz.part"
      echo "checksum mismatch for lua-$ver.tar.gz" >&2
      exit 1
    fi
    mv -- "$tgz.part" "$tgz"
  fi
  printf '%s\n' "$tgz"
}

build() { # version -> prints path to built luac
  local ver="$1" src="$cache/lua-$1"
  if [[ ! -d "$src" ]]; then
    tar -xzf "$cache/lua-$ver.tar.gz" -C "$cache"
  fi
  case "$ver" in
    5.0.*)
      # 5.0 has no platform targets; the top-level makefile reads ./config.
      # -fcommon: 5.0 relies on tentative definitions that newer GCC rejects.
      # 5.0 declares 'typedef unsigned long Instruction', which is 8 bytes on
      # LP64 Linux but 4 bytes on Windows and 32-bit targets. unluac (and the
      # test suite) expect 4-byte instructions, so pin it to 32 bits.
      if grep -q '^typedef unsigned long Instruction;' "$src/src/llimits.h"; then
        sed -i 's/^typedef unsigned long Instruction;/typedef unsigned int Instruction;/' "$src/src/llimits.h"
        make -C "$src" clean >&2
      fi
      log "building lua $ver (make)"
      make -C "$src" MYCFLAGS="-O2 -fcommon" >&2
      printf '%s\n' "$src/bin/luac"
      ;;
    *)
      log "building lua $ver (make linux)"
      make -C "$src" linux >&2
      printf '%s\n' "$src/src/luac"
      ;;
  esac
}

mkdir -p -- "$cache" "$bindir"

want=("$@")
for entry in "${targets[@]}"; do
  read -r name ver sum <<<"$entry"
  if (( ${#want[@]} )) && [[ ! " ${want[*]} " == *" $name "* ]]; then
    continue
  fi
  if [[ "${FORCE:-0}" != 1 ]] && installed_ok "$name" "$ver"; then
    log "$name ($ver) already installed, skipping"
    continue
  fi
  fetch "$ver" "$sum" >/dev/null
  luac="$(build "$ver")"
  install -m 0755 -- "$luac" "$bindir/$name"
  installed_ok "$name" "$ver" || { echo "$name does not report Lua $ver" >&2; exit 1; }
  log "installed $bindir/$name ($ver)"
done

case ":$PATH:" in
  *":$bindir:"*) ;;
  *) log "note: $bindir is not on PATH" ;;
esac
