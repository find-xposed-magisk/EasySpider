"""Update the version in all source and packaging metadata files.

Run this script from any directory, for example::

    python ElectronJS/change_version.py 0.6.5
"""

import argparse
import json
import re
from pathlib import Path


VERSION_RE = re.compile(r"^\d+\.\d+\.\d+$")
ROOT = Path(__file__).resolve().parent


def _read_text(path):
    with path.open("r", encoding="utf-8", newline="") as file:
        return file.read()


def _write_text(path, text):
    with path.open("w", encoding="utf-8", newline="") as file:
        file.write(text)


def update_text_file(path, prefix, version):
    text = _read_text(path)
    pattern = re.escape(prefix) + r"\d+\.\d+\.\d+"
    updated, count = re.subn(pattern, prefix + version, text)
    if count == 0:
        raise ValueError(f"Version marker not found in {path}: {prefix}")
    _write_text(path, updated)


def update_json_file(path, version, update_forge_app_version=False):
    original = _read_text(path)
    data = json.loads(original)
    data["version"] = version
    if isinstance(data.get("packages"), dict) and "" in data["packages"]:
        data["packages"][""]["version"] = version
    if update_forge_app_version:
        data["config"]["forge"]["packagerConfig"]["appVersion"] = version
    newline = "\r\n" if "\r\n" in original else "\n"
    _write_text(path, json.dumps(data, indent=4, ensure_ascii=False) + newline)


def update_version(version):
    update_text_file(ROOT.parent / ".temp_to_pub" / "compress.py", 'easyspider_version = "', version)
    update_text_file(ROOT / "src" / "taskGrid" / "logic.js", '"version": "', version)
    update_text_file(ROOT.parent / "ExecuteStage" / "easyspider_executestage.py", '"version": "', version)
    update_text_file(ROOT / "src" / "index.html", "软件当前版本：<b>v", version)
    update_text_file(ROOT / "src" / "index.html", "Current Version: <b>v", version)

    update_json_file(ROOT / "package.json", version, update_forge_app_version=True)
    update_json_file(ROOT / "package-lock.json", version)
    update_json_file(ROOT.parent / "Extension" / "manifest_v3" / "package.json", version)
    update_json_file(ROOT.parent / "Extension" / "manifest_v3" / "package-lock.json", version)
    update_json_file(ROOT.parent / "Extension" / "manifest_v3" / "src" / "manifest.json", version)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("version", help="new semantic version, for example 0.6.5")
    args = parser.parse_args()
    if not VERSION_RE.fullmatch(args.version):
        parser.error("version must have the form MAJOR.MINOR.PATCH")
    update_version(args.version)
    print(f"Updated EasySpider version to {args.version}")


if __name__ == "__main__":
    main()
