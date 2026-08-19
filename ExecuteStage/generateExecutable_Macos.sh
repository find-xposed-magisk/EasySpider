#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
PYTHON_BIN="${PYTHON_BIN:-python3}"

if [[ "$(uname -s)" != "Darwin" ]]; then
    echo "This script must run on macOS." >&2
    exit 1
fi

HOST_ARCH="$(uname -m)"
PYTHON_VERSION="$($PYTHON_BIN -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')"
PYTHON_ARCH="$($PYTHON_BIN -c 'import platform; print(platform.machine())')"
if [[ "$HOST_ARCH" != "arm64" && "$HOST_ARCH" != "x86_64" ]]; then
    echo "Unsupported macOS architecture: $HOST_ARCH" >&2
    exit 1
fi
if [[ "$PYTHON_VERSION" != "3.11" || "$PYTHON_ARCH" != "$HOST_ARCH" ]]; then
    echo "Native Python 3.11 $HOST_ARCH is required; found Python $PYTHON_VERSION $PYTHON_ARCH." >&2
    exit 1
fi

STAGE_DIR="$REPO_ROOT/.temp_to_pub/EasySpider_MacOS"
mkdir -p "$STAGE_DIR"
cd "$SCRIPT_DIR"

# The lightweight executor omits OCR and Pandas but retains Pillow, which is
# imported by the execution-stage program independently of OCR.
rm -rf build dist
"$PYTHON_BIN" -m PyInstaller \
    --noconfirm \
    --clean \
    --onefile \
    --target-arch "$HOST_ARCH" \
    --icon favicon.ico \
    --hidden-import selenium.webdriver.ie.webdriver \
    --exclude-module ddddocr \
    --exclude-module onnxruntime \
    --exclude-module onnx \
    --exclude-module pandas \
    --exclude-module numpy \
    --exclude-module scipy \
    --exclude-module sklearn \
    easyspider_executestage.py
install -m 755 dist/easyspider_executestage "$STAGE_DIR/easyspider_executestage"

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

rm -rf build dist
"$PYTHON_BIN" -m PyInstaller \
    --noconfirm \
    --clean \
    --onefile \
    --target-arch "$HOST_ARCH" \
    --icon favicon.ico \
    --hidden-import selenium.webdriver.ie.webdriver \
    --add-binary "$ONNX_STATE:onnxruntime/capi" \
    --add-data "$DDDDOCR_MODEL:ddddocr" \
    easyspider_executestage.py
install -m 755 dist/easyspider_executestage "$STAGE_DIR/easyspider_executestage_full"
echo "macOS $HOST_ARCH execution stages packaged successfully."
