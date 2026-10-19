// Install separately: npm install --prefix tmp/browser-tools playwright
// Optional: PLAYWRIGHT_MODULE, CHROMIUM_EXECUTABLE, GAME_URL, SMOKE_OUTPUT.
const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const {chromium} = require(process.env.PLAYWRIGHT_MODULE || path.resolve('tmp/browser-tools/node_modules/playwright'));

const output = process.env.SMOKE_OUTPUT || 'tmp/browser-smoke';
const baseUrl = process.env.GAME_URL || 'http://127.0.0.1:8765';
fs.mkdirSync(output, {recursive: true});

(async () => {
  const browser = await chromium.launch({
    headless: true,
    timeout: 15000,
    ...(process.env.CHROMIUM_EXECUTABLE ? {executablePath: process.env.CHROMIUM_EXECUTABLE} : {}),
    args: ['--autoplay-policy=no-user-gesture-required'],
  });
  const steps = [];
  const errors = [];
  try {
    const page = await browser.newPage({viewport: {width: 390, height: 844}, deviceScaleFactor: 1});
    page.setDefaultTimeout(15000);
    page.on('pageerror', error => errors.push(String(error)));
    page.on('console', message => { if (message.type() === 'error') errors.push(message.text()); });
    const capture = async name => {
      await page.screenshot({path: path.join(output, `${name}.png`)});
      steps.push({name, text: await page.locator('body').innerText()});
      console.log(`PASS ${name}`);
    };
    const openSettings = async () => {
      await page.getByRole('button', {name: 'Settings', exact: true}).click();
      await page.getByRole('switch', {name: 'Sound effects', exact: true}).waitFor();
    };
    const back = async () => {
      await page.getByRole('button', {name: 'Back', exact: true}).click();
      await page.getByRole('button', {name: /Play Adventure/}).first().waitFor();
    };

    await page.goto(baseUrl, {waitUntil: 'domcontentloaded'});
    await page.locator('flt-semantics-placeholder').evaluate(element => element.click());
    await page.getByRole('button', {name: /Play Adventure/}).first().waitFor();
    await capture('01-home');
    await openSettings();
    const soundSwitch = page.getByRole('switch', {name: 'Sound effects', exact: true});
    const motionSwitch = page.getByRole('switch', {name: /^Reduced motion/});
    await soundSwitch.click();
    await motionSwitch.click();
    assert.equal(await soundSwitch.getAttribute('aria-checked'), 'false');
    assert.equal(await motionSwitch.getAttribute('aria-checked'), 'true');
    await capture('02-settings');
    await back();
    await page.reload({waitUntil: 'domcontentloaded'});
    await page.locator('flt-semantics-placeholder').evaluate(element => element.click());
    await page.getByRole('button', {name: /Play Adventure/}).first().waitFor();
    await openSettings();
    assert.equal(await soundSwitch.getAttribute('aria-checked'), 'false', 'Sound preference survives reload.');
    assert.equal(await motionSwitch.getAttribute('aria-checked'), 'true', 'Motion preference survives reload.');
    await soundSwitch.click();
    await motionSwitch.click();
    await back();

    await page.getByRole('button', {name: /Play Adventure/}).first().click();
    await page.getByText('Island Recipe Journey', {exact: true}).waitFor();
    await capture('03-map');
    const firstLevel = page.getByRole('button', {name: 'Level 1, 0 stars', exact: true});
    const levelBounds = await firstLevel.boundingBox();
    assert(levelBounds && levelBounds.width <= 100 && levelBounds.height <= 100, 'Level action matches its visible circle.');
    await firstLevel.click();
    await page.getByRole('button', {name: /Start Level/}).first().waitFor();
    await capture('04-recipe');
    await page.getByRole('button', {name: /Start Level/}).first().click();
    await page.getByText('Moves: 27', {exact: true}).waitFor();
    const board = page.locator('[aria-label^="Playable "]').first();
    await board.waitFor();
    await page.waitForTimeout(800);
    await capture('05-gameplay');

    // Level 1's deterministic seed admits this opening match. Board padding
    // follows IslandMatchGame._layout (12 logical pixels on each side).
    const bounds = await board.boundingBox();
    assert(bounds && bounds.width > 200 && bounds.height > 200);
    const extent = Math.min(bounds.width - 24, bounds.height - 24);
    const cell = extent / 8;
    const x = bounds.x + (bounds.width - extent) / 2;
    const y = bounds.y + (bounds.height - extent) / 2;
    const center = (row, column) => ({x: x + (column + .5) * cell, y: y + (row + .5) * cell});
    const from = center(0, 2);
    const to = center(1, 2);
    await page.mouse.move(from.x, from.y);
    await page.mouse.down();
    await page.mouse.move(to.x, to.y, {steps: 8});
    await page.mouse.up();
    await page.getByText('Moves: 26', {exact: true}).waitFor();
    await page.waitForTimeout(1400);
    await capture('06-after-swap');

    await page.setViewportSize({width: 844, height: 390});
    await page.waitForTimeout(500);
    await capture('07-landscape');
    await page.getByRole('button', {name: 'Pause', exact: true}).click();
    await page.getByRole('button', {name: /Resume/}).first().waitFor();
    await capture('08-paused');
    await page.getByRole('button', {name: /Resume/}).first().click();
    await page.waitForTimeout(500);
    assert.equal(await page.getByText('Moves: 26', {exact: true}).count(), 1, 'Rotation and pause preserve the live board.');
    await page.setViewportSize({width: 768, height: 1024});
    await page.waitForTimeout(500);
    await capture('09-tablet');

    const sound = await page.evaluate(async () => {
      const audio = new Audio('assets/assets/audio/sfx/match.wav');
      const ended = new Promise((resolve, reject) => {
        const timeout = setTimeout(() => reject(new Error('Packaged match cue timed out.')), 4000);
        audio.addEventListener('ended', () => clearTimeout(timeout), {once: true});
        audio.addEventListener('ended', resolve, {once: true});
        audio.addEventListener('error', () => {
          clearTimeout(timeout);
          reject(new Error('Packaged match cue failed.'));
        }, {once: true});
      });
      await audio.play();
      await ended;
      return {duration: audio.duration};
    });
    assert(sound.duration > 0 && sound.duration < 2);
    assert.equal(errors.length, 0, errors.join('\n'));
    fs.writeFileSync(path.join(output, 'results.json'), JSON.stringify({steps, errors, sound}, null, 2));
    console.log('PASS navigation, saved settings, valid drag, rotation, pause/resume, tablet, and packaged audio.');
  } catch (error) {
    fs.writeFileSync(path.join(output, 'failure.json'), JSON.stringify({error: String(error), steps, errors}, null, 2));
    throw error;
  } finally {
    await browser.close();
  }
})().catch(error => { console.error(error); process.exitCode = 1; });
