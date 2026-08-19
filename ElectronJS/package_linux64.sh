#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
STAGE_DIR="$REPO_ROOT/.temp_to_pub/EasySpider_Linux_x64"

if [[ "$(uname -s)" != "Linux" || "$(uname -m)" != "x86_64" ]]; then
    echo "This script must run on a native Linux x86_64 build host." >&2
    exit 1
fi

CHROME_DIR="$SCRIPT_DIR/chrome_linux64"
for required_file in chrome chromedriver_linux64 chrome_crashpad_handler; do
    if [[ ! -f "$CHROME_DIR/$required_file" ]]; then
        echo "Missing Linux x64 browser file: $CHROME_DIR/$required_file" >&2
        exit 1
    fi
done

if [[ -f "$CHROME_DIR/chrome_sandbox" ]]; then
    CHROME_SANDBOX="$CHROME_DIR/chrome_sandbox"
elif [[ -f "$CHROME_DIR/chrome-sandbox" ]]; then
    CHROME_SANDBOX="$CHROME_DIR/chrome-sandbox"
else
    echo "Missing Chrome sandbox helper below $CHROME_DIR" >&2
    exit 1
fi

# main.js starts this launcher from chrome_linux64. Keep the launcher beside
# the execution-stage binary so it can resolve that binary relative to itself.
cp "$SCRIPT_DIR/execute_linux64.sh" "$CHROME_DIR/execute_linux64.sh"
for executable in chrome chromedriver_linux64 chrome_crashpad_handler \
    chrome-wrapper xdg-mime xdg-settings execute_linux64.sh; do
    if [[ -f "$CHROME_DIR/$executable" ]]; then
        chmod 755 "$CHROME_DIR/$executable"
    fi
done
chmod 755 "$CHROME_SANDBOX"

rm -rf "$SCRIPT_DIR/out"
(cd "$REPO_ROOT/Extension/manifest_v3" && node package.js)
(cd "$SCRIPT_DIR" && npm run package -- --platform=linux --arch=x64)

PACKAGED_APP="$SCRIPT_DIR/out/EasySpider-linux-x64"
if [[ ! -d "$PACKAGED_APP" ]]; then
    echo "Electron Forge did not produce $PACKAGED_APP" >&2
    exit 1
fi

APP_RESOURCES="$PACKAGED_APP/resources/app"
rm -rf "$APP_RESOURCES/chrome_win32" "$APP_RESOURCES/chrome_win64" \
    "$APP_RESOURCES/chrome_mac64.app" \
    "$APP_RESOURCES/chromedrivers" "$APP_RESOURCES/Data" \
    "$APP_RESOURCES/.idea" "$APP_RESOURCES/tasks" \
    "$APP_RESOURCES/execution_instances" "$APP_RESOURCES/user_data" \
    "$APP_RESOURCES/TempUserDataFolder"
rm -f "$APP_RESOURCES/vs_BuildTools.exe" "$APP_RESOURCES/VS_BuildTools.exe" \
    "$APP_RESOURCES/chromedriver_mac64"

mkdir -p "$STAGE_DIR"
rm -rf "$STAGE_DIR/EasySpider" "$STAGE_DIR/Code" "$STAGE_DIR/Data" \
    "$STAGE_DIR/execution_instances" "$STAGE_DIR/tasks" \
    "$STAGE_DIR/user_data" "$STAGE_DIR/TempUserDataFolder"
rm -f "$STAGE_DIR/config.json" "$STAGE_DIR/mysql_config.json"
mkdir -p "$STAGE_DIR/Code" "$STAGE_DIR/Data" "$STAGE_DIR/execution_instances" "$STAGE_DIR/tasks"
mv "$PACKAGED_APP" "$STAGE_DIR/EasySpider"

cp "$REPO_ROOT/ExecuteStage"/*.py "$STAGE_DIR/Code/"
cp "$REPO_ROOT/ExecuteStage/requirements.txt" "$STAGE_DIR/Code/"
cp "$REPO_ROOT/ExecuteStage/Readme.md" "$STAGE_DIR/Code/"
cp "$REPO_ROOT/ExecuteStage/myCode.py" "$STAGE_DIR/"
cp -R "$REPO_ROOT/ExecuteStage/undetected_chromedriver_ES" "$STAGE_DIR/Code/"
cp -R "$REPO_ROOT/ExecuteStage/.vscode" "$STAGE_DIR/Code/"

find "$STAGE_DIR" -type d -name __pycache__ -prune -exec rm -rf {} +
find "$STAGE_DIR" -type d -name .pytest_cache -prune -exec rm -rf {} +

copy_tracked_tasks() {
    while IFS= read -r -d '' task; do
        relative="${task#tasks/}"
        destination="$STAGE_DIR/tasks/$relative"
        mkdir -p "$(dirname -- "$destination")"
        cp "$SCRIPT_DIR/$task" "$destination"
    done < <(git -c safe.directory='*' -C "$SCRIPT_DIR" ls-files -z -- tasks)
}
copy_tracked_tasks

chmod 755 "$STAGE_DIR/easy-spider.sh" "$STAGE_DIR/first_time_run.sh" 2>/dev/null || true
STAGED_CHROME_DIR="$STAGE_DIR/EasySpider/resources/app/chrome_linux64"
for executable in chrome chromedriver_linux64 chrome_crashpad_handler \
    chrome_sandbox chrome-sandbox chrome-wrapper xdg-mime xdg-settings \
    easyspider_executestage execute_linux64.sh; do
    if [[ -f "$STAGED_CHROME_DIR/$executable" ]]; then
        chmod 755 "$STAGED_CHROME_DIR/$executable"
    fi
done
echo "Linux x64 application staged at $STAGE_DIR"
