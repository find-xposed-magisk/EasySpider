# XPath Helper for EasySpider

This directory is a Manifest V3 compatibility port of the XPath Helper 2.0.2
extension previously distributed in this repository as `XPathHelper.crx`.

The original source files identify Google Inc. and `opensource@google.com` as
their author and are licensed under the Apache License, Version 2.0. The
original CRX bundled by EasySpider has SHA-256:

`CA08441B51C00DAD6DDAF6713A6F4F613465253198B1FB376A3E57FEC1903EFD`

EasySpider's 2026 compatibility changes are limited to:

- replacing Manifest V2 with Manifest V3;
- replacing the background page with a service worker;
- replacing `chrome.browserAction` with `chrome.action`;
- updating the web-accessible resource declaration;
- loading the unpacked extension through WebDriver BiDi.

The XPath bar, XPath evaluation, element highlighting, Ctrl+Shift+X shortcut,
and toolbar action behavior remain based on the original implementation.

See `LICENSE` for the full Apache-2.0 terms.
