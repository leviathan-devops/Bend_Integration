#!/bin/sh
# Install the Bend 2.0.32 linux-x64 release this tree was checked with.
# The sha256 is of the official GitHub release asset.
set -eu

VER=2.0.32
SUM=5c365ddb12954d0933cef751802e0f7d9875f842edcb80f9661f89cd1a9ff7b6

case "$(uname -s)-$(uname -m)" in
  Linux-x86_64|Linux-amd64) ;;
  *)
    echo "bend install: this script pins the linux-x64 asset only" >&2
    exit 1
    ;;
esac

home="${BEND_HOME:-$HOME/.bend}"
name="bend-${VER}-linux-x64.tar.gz"
url="https://github.com/bendlang/bend/releases/download/v${VER}/${name}"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

curl --proto '=https' --tlsv1.2 -fsSL -o "$tmp/$name" "$url"
echo "${SUM}  $tmp/$name" | sha256sum -c -
mkdir -p "$home/bin" "$tmp/extract"
tar -xzf "$tmp/$name" -C "$tmp/extract"
rm -rf "$home/bend2" "$home/guide"
mv "$tmp/extract/bend/bend2" "$tmp/extract/bend/guide" "$home/"
mv -f "$tmp/extract/bend/bin/bend" "$home/bin/bend"
if [ -n "${GITHUB_PATH:-}" ]; then
  echo "$home/bin" >> "$GITHUB_PATH"
fi
echo "installed $($home/bin/bend version) at $home/bin/bend"
