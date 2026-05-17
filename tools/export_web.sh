#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT_BIN="${GODOT_BIN:-/Applications/Godot.app/Contents/MacOS/Godot}"
TEMPLATE_DIR="${GODOT_TEMPLATE_DIR:-$HOME/Library/Application Support/Godot/export_templates/4.6.2.stable}"
TEMPLATE_ZIP="$TEMPLATE_DIR/web_nothreads_release.zip"
OUT="$ROOT/builds/web"

if [[ ! -x "$GODOT_BIN" ]]; then
  echo "Godot executable not found: $GODOT_BIN" >&2
  exit 1
fi

if [[ ! -f "$TEMPLATE_ZIP" ]]; then
  echo "Web export template not found: $TEMPLATE_ZIP" >&2
  echo "Install Godot 4.6.2 export templates first." >&2
  exit 1
fi

mkdir -p "$OUT"

"$GODOT_BIN" --headless --path "$ROOT" --export-pack Web "$OUT/index.pck"

unzip -p "$TEMPLATE_ZIP" godot.js > "$OUT/index.js"
unzip -p "$TEMPLATE_ZIP" godot.wasm > "$OUT/index.wasm"
unzip -p "$TEMPLATE_ZIP" godot.audio.worklet.js > "$OUT/index.audio.worklet.js"
unzip -p "$TEMPLATE_ZIP" godot.audio.position.worklet.js > "$OUT/index.audio.position.worklet.js"
unzip -p "$TEMPLATE_ZIP" godot.html > "$OUT/index.html.template"

python3 - "$OUT/index.html.template" "$OUT/index.html" "$OUT/index.pck" "$OUT/index.wasm" <<'PY'
import json
import os
import sys

template_path, output_path, pck_path, wasm_path = sys.argv[1:5]

config = {
    "args": [],
    "canvasResizePolicy": 2,
    "executable": "index",
    "experimentalVK": False,
    "fileSizes": {
        "index.pck": os.path.getsize(pck_path),
        "index.wasm": os.path.getsize(wasm_path),
    },
    "focusCanvas": True,
    "gdextensionLibs": [],
    "serviceWorker": "",
}

with open(template_path, "r", encoding="utf-8") as f:
    html = f.read()

html = (
    html
    .replace("$GODOT_PROJECT_NAME", "Cat Dog Battle")
    .replace("$GODOT_SPLASH_COLOR", "#000000")
    .replace("$GODOT_SPLASH_CLASSES", "show-image--false fullsize--false use-filter--false")
    .replace("$GODOT_SPLASH", "")
    .replace("$GODOT_HEAD_INCLUDE", "")
    .replace("$GODOT_URL", "index.js")
    .replace("$GODOT_CONFIG", json.dumps(config, separators=(",", ":")))
    .replace("$GODOT_THREADS_ENABLED", "false")
)

with open(output_path, "w", encoding="utf-8") as f:
    f.write(html)
PY

rm -f "$OUT/index.html.template"

echo "Web build written to $OUT"
echo "Serve it with: python3 -m http.server 8765 --bind 127.0.0.1 --directory \"$OUT\""
