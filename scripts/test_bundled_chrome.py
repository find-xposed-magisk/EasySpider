"""Verify the Chrome/ChromeDriver bundled in a Windows EasySpider package."""

from __future__ import annotations

import argparse
import json
from pathlib import Path

from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.common.by import By


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--stage",
        type=Path,
        default=Path(".temp_to_pub/EasySpider_windows_x64"),
        help="root of the staged Windows package",
    )
    parser.add_argument("--url", default="https://example.com/")
    args = parser.parse_args()

    app = args.stage.resolve() / "EasySpider" / "resources" / "app"
    chrome_binary = app / "chrome_win64" / "chrome.exe"
    chrome_driver = app / "chrome_win64" / "chromedriver_win64.exe"
    if not chrome_binary.is_file() or not chrome_driver.is_file():
        raise FileNotFoundError(f"bundled browser files are missing below {app}")

    options = webdriver.ChromeOptions()
    options.binary_location = str(chrome_binary)
    options.add_argument("--headless=new")
    options.add_argument("--disable-gpu")
    options.add_argument("--no-first-run")
    options.add_argument("--no-default-browser-check")
    options.add_argument("--ignore-certificate-errors")

    driver = webdriver.Chrome(service=Service(str(chrome_driver)), options=options)
    try:
        driver.set_page_load_timeout(30)
        driver.get(args.url)
        heading = driver.find_element(By.TAG_NAME, "h1").text.strip()
        assert driver.title == "Example Domain", driver.title
        assert heading == "Example Domain", heading
        print(
            json.dumps(
                {
                    "url": driver.current_url,
                    "title": driver.title,
                    "heading": heading,
                    "browser_version": driver.capabilities.get("browserVersion"),
                    "platform": driver.capabilities.get("platformName"),
                    "chrome_binary": str(chrome_binary),
                    "chrome_driver": str(chrome_driver),
                },
                ensure_ascii=False,
                indent=2,
            )
        )
    finally:
        driver.quit()


if __name__ == "__main__":
    main()
