#!/usr/bin/env node

// Windows smoke test for the two unpacked extensions loaded by EasySpider.
// It uses the same Chrome, ChromeDriver, WebDriver BiDi helper and Chrome
// flags as ElectronJS/main.js, but serves a deterministic local test page.

const http = require('http');
const path = require('path');

const repoRoot = path.resolve(__dirname, '..');
const electronRoot = process.env.EASYSPIDER_ELECTRON_ROOT
  ? path.resolve(process.env.EASYSPIDER_ELECTRON_ROOT)
  : path.join(repoRoot, 'ElectronJS');
const seleniumRoot = path.join(electronRoot, 'node_modules', 'selenium-webdriver');

const {Builder, By, Key, until} = require(seleniumRoot);
const chrome = require(path.join(seleniumRoot, 'chrome'));
const getWebExtensionInstance = require(
  path.join(electronRoot, 'selenium-webdriver-bidi-webExtension', 'webExtension')
);
const ExtensionData = require(
  path.join(electronRoot, 'selenium-webdriver-bidi-webExtension', 'extensionData')
);

const chromeBinary = path.join(electronRoot, 'chrome_win64', 'chrome.exe');
const chromeDriver = path.join(
  electronRoot,
  'chrome_win64',
  'chromedriver_win64.exe'
);
const easySpiderExtension = path.join(electronRoot, 'EasySpider_zh');
const xpathHelperExtension = path.join(electronRoot, 'XPathHelper_MV3');
const legacyXpathHelper = path.join(electronRoot, 'XPathHelper.crx');

function startTestServer() {
  const html = `<!doctype html>
<html>
  <head><meta charset="utf-8"><title>XPath Helper BiDi Test</title></head>
  <body>
    <h1 id="smoke-title">XPath Smoke Test</h1>
    <div class="item">first</div>
    <div class="item">second</div>
  </body>
</html>`;

  const server = http.createServer((request, response) => {
    response.writeHead(200, {'Content-Type': 'text/html; charset=utf-8'});
    response.end(html);
  });

  return new Promise((resolve, reject) => {
    server.once('error', reject);
    server.listen(0, '127.0.0.1', () => resolve(server));
  });
}

function closeServer(server) {
  return new Promise((resolve) => server.close(resolve));
}

async function main() {
  const server = await startTestServer();
  const address = server.address();
  let driver;

  try {
    const options = new chrome.Options();
    options.setChromeBinaryPath(chromeBinary);
    options.set('webSocketUrl', true);
    options.set('excludeSwitches', ['enable-automation']);
    options.set('useAutomationExtension', false);
    options.addArguments('--enable-unsafe-extension-debugging');
    options.addArguments('--remote-debugging-pipe');
    options.addArguments('--disable-blink-features=AutomationControlled');
    options.addArguments('--disable-infobars');
    options.addArguments('--disable-gpu');
    options.addArguments('--no-first-run');
    options.addArguments('--no-default-browser-check');
    if (process.env.HEADED !== '1') {
      options.addArguments('--headless=new');
    }

    const serviceBuilder = new chrome.ServiceBuilder(chromeDriver);
    driver = await new Builder()
      .forBrowser('chrome')
      .setChromeOptions(options)
      .setChromeService(serviceBuilder)
      .build();

    const webExtension = await getWebExtensionInstance(driver);
    let legacyArchiveError = null;
    let legacyPathError = null;
    if (process.env.TEST_LEGACY === '1') {
      try {
        await webExtension.install(ExtensionData.setArchivePath(legacyXpathHelper));
      } catch (error) {
        legacyArchiveError = String(error && (error.stack || error.message || error));
      }
    }
    if (process.env.LEGACY_UNPACKED_PATH) {
      try {
        await webExtension.install(
          ExtensionData.setPath(path.resolve(process.env.LEGACY_UNPACKED_PATH))
        );
      } catch (error) {
        legacyPathError = String(error && (error.stack || error.message || error));
      }
    }

    const easySpiderId = await webExtension.install(
      ExtensionData.setPath(easySpiderExtension)
    );
    const xpathHelperId = await webExtension.install(
      ExtensionData.setPath(xpathHelperExtension)
    );

    await driver.get(`http://127.0.0.1:${address.port}/`);
    await driver.wait(until.elementLocated(By.id('smoke-title')), 10000);

    await driver.actions()
      .keyDown(Key.CONTROL)
      .keyDown(Key.SHIFT)
      .sendKeys('x')
      .keyUp(Key.SHIFT)
      .keyUp(Key.CONTROL)
      .perform();

    const xpathFrame = await driver.wait(
      until.elementLocated(By.id('xh-bar')),
      10000
    );
    await driver.wait(async () => {
      return !(await xpathFrame.getAttribute('class')).split(/\s+/).includes('hidden');
    }, 10000);

    await driver.switchTo().frame(xpathFrame);
    const query = await driver.findElement(By.id('query'));
    await query.clear();
    await query.sendKeys('//h1');

    const nodeCount = await driver.findElement(By.id('node-count'));
    await driver.wait(async () => (await nodeCount.getText()) === '1', 10000);
    const nodeCountText = await nodeCount.getText();
    const resultText = await driver.findElement(By.id('results')).getAttribute('value');

    await driver.switchTo().defaultContent();
    const highlighted = await driver.executeScript(
      "return document.querySelectorAll('.xh-highlight').length"
    );
    const title = await driver.getTitle();

    if (highlighted !== 1) {
      throw new Error(`Expected one highlighted XPath match, got ${highlighted}`);
    }

    console.log(JSON.stringify({
      chromeBinary,
      chromeDriver,
      easySpiderId,
      xpathHelperId,
      title,
      nodeCount: nodeCountText,
      resultText,
      highlighted,
      legacyArchiveTested: process.env.TEST_LEGACY === '1',
      legacyArchiveRejected: legacyArchiveError !== null,
      legacyArchiveError,
      legacyPathTested: Boolean(process.env.LEGACY_UNPACKED_PATH),
      legacyPathRejected: legacyPathError !== null,
      legacyPathError,
    }, null, 2));
  } finally {
    if (driver) {
      await driver.quit();
    }
    await closeServer(server);
  }
}

main().catch((error) => {
  console.error(error && (error.stack || error));
  process.exitCode = 1;
});
