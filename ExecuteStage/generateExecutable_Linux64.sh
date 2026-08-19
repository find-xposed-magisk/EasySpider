#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
PYTHON_BIN="${PYTHON_BIN:-python3}"

if [[ "$(uname -s)" != "Linux" || "$(uname -m)" != "x86_64" ]]; then
    echo "This script must run on a native Linux x86_64 build host." >&2
    exit 1
fi

PYTHON_VERSION="$($PYTHON_BIN -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')"
PYTHON_ARCH="$($PYTHON_BIN -c 'import platform; print(platform.machine())')"
if [[ "$PYTHON_VERSION" != "3.11" || "$PYTHON_ARCH" != "x86_64" ]]; then
    echo "Python 3.11 x86_64 is required; found Python $PYTHON_VERSION $PYTHON_ARCH." >&2
    exit 1
fi

DDDDOCR_MODEL="$($PYTHON_BIN -c 'import ddddocr, pathlib; print(pathlib.Path(ddddocr.__file__).resolve().parent / "common_old.onnx")')"
ONNX_STATE="$($PYTHON_BIN -c 'import onnxruntime, pathlib; capi = pathlib.Path(onnxruntime.__file__).resolve().parent / "capi"; matches = sorted(capi.glob("onnxruntime_pybind11_state*.so")); print(matches[0] if matches else "")')"

if [[ ! -f "$DDDDOCR_MODEL" ]]; then
    echo "Could not find ddddocr/common_old.onnx in the active Python environment." >&2
    exit 1
fi
if [[ ! -f "$ONNX_STATE" ]]; then
    echo "Could not find onnxruntime_pybind11_state*.so in the active Python environment." >&2
    exit 1
fi

cd "$SCRIPT_DIR"
rm -rf build dist

"$PYTHON_BIN" -m PyInstaller \
    --noconfirm \
    --clean \
    --onefile \
    --hidden-import selenium.webdriver.ie.webdriver \
    --add-binary "$ONNX_STATE:onnxruntime/capi" \
    --add-data "$DDDDOCR_MODEL:ddddocr" \
    easyspider_executestage.py

TARGET_DIR="$REPO_ROOT/ElectronJS/chrome_linux64"
mkdir -p "$TARGET_DIR"
install -m 755 dist/easyspider_executestage "$TARGET_DIR/easyspider_executestage"
echo "Linux x64 execution stage packaged successfully."
