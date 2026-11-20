#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

device="iPhone 18 Pro"
locale="en-US"
output="fastlane/screenshots/$locale"
screens=(01-search 02-history 03-detail 04-spatial)

FASTLANE_SKIP_DOCS=1 fastlane ios screenshots "device:$device" "locale:$locale"

for screen in "${screens[@]}"; do
  source="$output/$device-${screen}_framed_512.png"
  if [[ ! -s "$source" ]]; then
    printf 'Missing screenshot: %s\n' "$source" >&2
    exit 1
  fi
done

for index in "${!screens[@]}"; do
  cp "$output/$device-${screens[$index]}_framed_512.png" "assets/screen$((index + 1)).png"
done
