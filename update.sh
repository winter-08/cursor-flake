#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl jq coreutils nix _7zz
set -euo pipefail

cd -- "$(dirname "${BASH_SOURCE[0]}")"

meta=$(curl -fsSL "https://api2.cursor.sh/updates/api/download/stable/linux-x64/cursor")
version=$(jq -r '.version' <<< "$meta")
current=$(jq -r '.version' sources.json)

if [[ "$version" == "$current" ]]; then
  echo "Already up to date ($version)"
  exit 0
fi

sources='{}'
vscode_version=''

for pair in \
  x86_64-linux:linux-x64 \
  aarch64-linux:linux-arm64 \
  x86_64-darwin:darwin-x64 \
  aarch64-darwin:darwin-arm64
do
  IFS=: read -r system platform <<< "$pair"
  meta=$(curl -fsSL "https://api2.cursor.sh/updates/api/download/stable/$platform/cursor")
  platform_version=$(jq -r '.version' <<< "$meta")

  if [[ "$platform_version" != "$version" ]]; then
    echo "Version mismatch: $system has $platform_version, expected $version" >&2
    exit 1
  fi

  url=$(jq -r '.downloadUrl' <<< "$meta")
  {
    read -r hash
    read -r path
  } < <(nix-prefetch-url --print-path "$url")
  sri=$(nix-hash --type sha256 --to-sri "$hash")

  if [[ "$system" == "x86_64-linux" ]]; then
    vscode_version=$(7zz x -so "$path" "usr/share/cursor/resources/app/product.json" 2>/dev/null | jq -r '.vscodeVersion')
  fi

  sources=$(
    jq -n \
      --argjson src "$sources" \
      --arg system "$system" \
      --arg url "$url" \
      --arg hash "$sri" \
      '$src + {($system): {url: $url, hash: $hash}}'
  )
done

jq -n \
  --arg version "$version" \
  --arg vscodeVersion "$vscode_version" \
  --argjson sources "$sources" \
  '{
    version: $version,
    vscodeVersion: $vscodeVersion,
    sources: $sources
  }' > sources.json
