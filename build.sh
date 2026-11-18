#!/usr/bin/env bash
# Builds the exports locally. Usage: ./build.sh [windows|linux|android|web|all|test]
# Needs Godot 4.7 in the PATH (or GODOT=/path/to/godot) and the export templates installed.
set -euo pipefail
cd "$(dirname "$0")"
GODOT="${GODOT:-godot}"
target="${1:-all}"

"$GODOT" --headless --import >/dev/null 2>&1 || true

build() {
  mkdir -p "$(dirname "$2")"
  echo ">> $1 -> $2"
  # Android is exported in debug mode (signed with the debug key) so it installs right away on a phone.
  local mode="--export-release"
  [ "$1" = "Android" ] && mode="--export-debug"
  "$GODOT" --headless "$mode" "$1" "$2"
}

case "$target" in
  test)    "$GODOT" --headless -s res://tests/run_tests.gd ;;
  windows) build "Windows" builds/windows/ClassicArcade.exe ;;
  linux)   build "Linux" builds/linux/ClassicArcade.x86_64 ;;
  android) build "Android" builds/android/ClassicArcade.apk ;;
  web)     build "Web" builds/web/index.html ;;
  all)
    build "Windows" builds/windows/ClassicArcade.exe
    build "Linux" builds/linux/ClassicArcade.x86_64
    build "Android" builds/android/ClassicArcade.apk || echo "!! Android failed: check the SDK/keystore in the Editor Settings."
    build "Web" builds/web/index.html
    ;;
  *) echo "Unknown target: $target"; exit 1 ;;
esac
