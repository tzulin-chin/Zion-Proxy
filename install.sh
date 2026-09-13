#!/bin/sh
set -eu
repo=tzulin-chin/Zion-Proxy
version=latest
destination=${HOME}/.local/bin
while [ "$#" -gt 0 ]; do
  case "$1" in
    --version) version=${2:?missing version}; shift 2 ;;
    --bin-dir) destination=${2:?missing directory}; shift 2 ;;
    --help) echo 'Usage: sh install.sh [--version v0.1.1] [--bin-dir ~/.local/bin]'; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done
for tool in curl tar awk uname; do command -v "$tool" >/dev/null || { echo "Missing $tool" >&2; exit 1; }; done
case "$(uname -s)" in Darwin) os=darwin ;; Linux) os=linux ;; *) echo 'Only macOS and Linux (glibc) are supported' >&2; exit 1 ;; esac
case "$(uname -m)" in arm64|aarch64) arch=arm64 ;; x86_64|amd64) arch=x64 ;; *) echo 'Unsupported CPU' >&2; exit 1 ;; esac
if [ "$version" = latest ]; then
  url=$(curl --proto '=https' --tlsv1.2 -fsSL --max-time 30 -o /dev/null -w '%{url_effective}' "https://github.com/$repo/releases/latest")
  version=${url##*/}
fi
# Validate before using the tag in URLs, filenames, or tar members.
echo "$version" | LC_ALL=C awk '/^v[0-9]+\.[0-9]+\.[0-9]+(\.[0-9]+)?(-[0-9A-Za-z]+([.-][0-9A-Za-z]+)*)?$/ {ok=1} END {exit !ok}' || { echo 'Invalid release version' >&2; exit 1; }
mkdir -p "$destination"
destination=$(cd "$destination" && pwd)
target=$destination/opc
[ ! -L "$target" ] || { echo 'Refusing to replace a symlink; choose a real --bin-dir' >&2; exit 1; }
if [ -e "$target" ]; then
  current=$("$target" --version) || { echo 'Existing opc is not a working binary' >&2; exit 1; }
  case "$current" in 'opc '*) ;; *) echo 'Refusing to replace an unrelated opc executable' >&2; exit 1 ;; esac
  if [ "$current" = "opc ${version#v}" ]; then echo "Already installed: $target ($version)"; exit 0; fi
fi
lock=$target.update-lock
mkdir "$lock" 2>/dev/null || { echo "Install/update lock exists: $lock" >&2; exit 1; }
stage=
cleanup() { [ -z "$stage" ] || rm -rf "$stage"; rmdir "$lock" 2>/dev/null || true; }
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
stage=$(mktemp -d "$destination/.opc-install.XXXXXX")
archive=opc-$version-$os-$arch.tar.gz
base=https://github.com/$repo/releases/download/$version
curl --proto '=https' --tlsv1.2 -fsSL --max-time 180 "$base/$archive" -o "$stage/$archive"
curl --proto '=https' --tlsv1.2 -fsSL --max-time 30 "$base/SHA256SUMS" -o "$stage/SHA256SUMS"
expected=$(awk -v file="$archive" '$2 == file {hash=$1; n++} END {if (n != 1) exit 1; print hash}' "$stage/SHA256SUMS")
if command -v sha256sum >/dev/null; then actual=$(sha256sum "$stage/$archive" | awk '{print $1}');
else actual=$(shasum -a 256 "$stage/$archive" | awk '{print $1}'); fi
[ "$actual" = "$expected" ] || { echo 'Checksum mismatch; existing binary preserved' >&2; exit 1; }
member=opc-$version-$os-$arch/opc
tar -tzf "$stage/$archive" | awk -v file="$member" '$0 == file {n++} END {exit n != 1}' || { echo 'Invalid archive' >&2; exit 1; }
# Only this exact member is copied; no archive paths are extracted onto the filesystem.
tar -xOzf "$stage/$archive" "$member" > "$stage/opc"
chmod 755 "$stage/opc"
[ "$("$stage/opc" --version)" = "opc ${version#v}" ] || { echo 'Binary verification failed' >&2; exit 1; }
if [ -e "$target" ]; then
  cp -p "$target" "$stage/previous"
  mv -f "$stage/previous" "$target.previous"
fi
mv -f "$stage/opc" "$target"
echo "Installed: $target ($version)"
echo 'Keep this bin directory in PATH. Existing services require a restart to load the new binary.'
