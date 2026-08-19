#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$SCRIPT_DIR/EasySpider"
CHROME_DIR="$APP_DIR/resources/app/chrome_linux64"

for executable in chrome chromedriver_linux64 chrome_crashpad_handler \
    chrome-wrapper xdg-mime xdg-settings easyspider_executestage \
    execute_linux64.sh; do
    if [[ -f "$CHROME_DIR/$executable" ]]; then
        chmod 755 "$CHROME_DIR/$executable"
    fi
done

configure_sandbox() {
    local sandbox_path="$1"
    local owner
    local permissions

    [[ -f "$sandbox_path" ]] || return 0
    owner="$(stat -c %U "$sandbox_path")"
    permissions="$(stat -c %a "$sandbox_path")"
    if [[ "$owner" != "root" || "$permissions" != "4755" ]]; then
        echo "EasySpider needs to configure its Chromium sandbox once."
        echo "EasySpider 首次运行需要配置 Chromium 沙箱权限。"
        sudo chown root:root "$sandbox_path"
        sudo chmod 4755 "$sandbox_path"
    fi
}

configure_sandbox "$APP_DIR/chrome-sandbox"

if [[ -f "$CHROME_DIR/chrome_sandbox" ]]; then
    configure_sandbox "$CHROME_DIR/chrome_sandbox"
elif [[ -f "$CHROME_DIR/chrome-sandbox" ]]; then
    configure_sandbox "$CHROME_DIR/chrome-sandbox"
else
    echo "Chrome sandbox helper is missing below $CHROME_DIR" >&2
    exit 1
fi

exec "$APP_DIR/EasySpider"
