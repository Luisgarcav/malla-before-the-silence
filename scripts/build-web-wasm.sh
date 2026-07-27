#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
project_root="$(cd -- "$script_dir/.." && pwd)"

odin build "$project_root/src" \
  -target:js_wasm32 \
  -out:"$project_root/web/static/game.wasm" \
  -o:size \
  -vet \
  -warnings-as-errors
