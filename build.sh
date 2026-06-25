#!/usr/bin/env bash
# Build machin-web-demo-reactive: a fine-grained reactive counter compiled to wasm.
#
#   ./build.sh   # → app.wasm
#
# Composes the reactive runtime (vendored reactive.src, from machin/framework) with
# the app, then compiles to a wasm reactor module. Needs machin v0.53.0+ (slices of
# functions, []func) and zig (the C→wasm compiler). Serve over http and open it.
set -euo pipefail
cd "$(dirname "$0")"
MACHIN="${MACHIN:-machin}"

"$MACHIN" encode reactive.src app.src > app.mfl
"$MACHIN" build app.mfl --target wasm -o app.wasm

echo "built ./app.wasm ($(wc -c < app.wasm) bytes)"
echo "serve with:  python3 -m http.server 8000   then open http://localhost:8000/"
