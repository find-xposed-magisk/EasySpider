"""Small, side-effect-free smoke tests for EasySpider's Python dependencies."""

from __future__ import annotations

import io
import json
from importlib import metadata


def package_version(distribution: str) -> str:
    return metadata.version(distribution)


def main() -> None:
    results: dict[str, object] = {}

    # Image: exercise both Pillow and OpenCV using an in-memory PNG.
    import cv2
    import numpy as np
    from PIL import Image, ImageDraw

    image = Image.new("RGB", (96, 32), "white")
    ImageDraw.Draw(image).text((8, 8), "1234", fill="black")
    png = io.BytesIO()
    image.save(png, format="PNG")
    png_bytes = png.getvalue()
    decoded = cv2.imdecode(np.frombuffer(png_bytes, dtype=np.uint8), cv2.IMREAD_COLOR)
    assert image.rotate(90, expand=True).size == (32, 96)
    assert decoded is not None and decoded.shape[:2] == (32, 96)
    results["image"] = {
        "Pillow": package_version("Pillow"),
        "opencv-python": package_version("opencv-python"),
        "decoded_shape": list(decoded.shape),
    }

    # OCR: initialize the bundled ONNX model and perform one inference.
    import ddddocr

    ocr = ddddocr.DdddOcr(show_ad=False)
    ocr_text = ocr.classification(png_bytes)
    assert isinstance(ocr_text, str)
    results["ocr"] = {
        "ddddocr": package_version("ddddocr"),
        "onnxruntime": package_version("onnxruntime"),
        "result_type": type(ocr_text).__name__,
    }

    # HTML/XML: parse HTML with BeautifulSoup and evaluate XML XPath with lxml.
    from bs4 import BeautifulSoup
    from lxml import etree

    soup = BeautifulSoup("<main><h1>EasySpider</h1></main>", "html.parser")
    assert soup.select_one("h1").get_text(strip=True) == "EasySpider"
    xml_root = etree.fromstring(b"<root><item id='1'>ok</item></root>")
    assert xml_root.xpath("string(/root/item[@id='1'])") == "ok"
    results["html_xml"] = {
        "beautifulsoup4": package_version("beautifulsoup4"),
        "lxml": package_version("lxml"),
    }

    # Excel: write with XlsxWriter and read the same workbook with openpyxl.
    import openpyxl
    import xlsxwriter

    workbook_bytes = io.BytesIO()
    workbook = xlsxwriter.Workbook(workbook_bytes, {"in_memory": True})
    sheet = workbook.add_worksheet("Smoke")
    sheet.write(0, 0, "EasySpider")
    sheet.write_number(0, 1, 65)
    workbook.close()
    workbook_bytes.seek(0)
    loaded = openpyxl.load_workbook(workbook_bytes, read_only=True, data_only=True)
    assert loaded["Smoke"]["A1"].value == "EasySpider"
    assert loaded["Smoke"]["B1"].value == 65
    loaded.close()
    results["excel"] = {
        "xlsxwriter": package_version("xlsxwriter"),
        "openpyxl": package_version("openpyxl"),
    }

    # Pandas: exercise DataFrame creation, grouping, and aggregation.
    import pandas as pd

    frame = pd.DataFrame({"group": ["a", "a", "b"], "value": [1, 2, 3]})
    totals = frame.groupby("group", sort=True)["value"].sum().to_dict()
    assert totals == {"a": 3, "b": 3}
    results["pandas"] = {"pandas": package_version("pandas"), "totals": totals}

    # Selenium: construct real Chrome options and an XPath locator without starting Chrome.
    from selenium import webdriver
    from selenium.webdriver.common.by import By

    options = webdriver.ChromeOptions()
    options.add_argument("--headless=new")
    locator = (By.XPATH, "//h1")
    assert "--headless=new" in options.arguments and locator == ("xpath", "//h1")
    results["selenium"] = {
        "selenium": package_version("selenium"),
        "arguments": options.arguments,
        "locator": list(locator),
    }

    # Keyboard: construct key representations without injecting input into the OS.
    from pynput.keyboard import Key, KeyCode

    pause_key = KeyCode.from_char("p")
    assert pause_key.char == "p" and Key.space.value is not None
    results["keyboard"] = {"pynput": package_version("pynput"), "pause_key": pause_key.char}

    # MySQL client: exercise PyMySQL's query-string escaping without needing credentials.
    import pymysql
    from pymysql.converters import escape_string

    escaped = escape_string("O'Reilly")
    assert escaped == "O\\'Reilly"
    results["mysql_client"] = {"PyMySQL": package_version("PyMySQL"), "escaped": escaped}

    print(json.dumps(results, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
