import { chromium } from 'playwright';
import { mkdirSync, rmSync, writeFileSync } from 'node:fs';

rmSync('out', { recursive: true, force: true });
mkdirSync('out', { recursive: true });
const log = [];
const browser = await chromium.launch();

async function open(route) {
  const page = await browser.newPage({
    viewport: { width: 430, height: 620 },
    deviceScaleFactor: 2,
  });
  page.on('pageerror', (e) => log.push(`[${route}] pageerror: ${e.message}`));
  page.on('console', (m) => {
    if (m.type() === 'error') log.push(`[${route}] console: ${m.text()}`);
  });
  await page.goto(`http://localhost:8080/#${route}`, { waitUntil: 'networkidle' });
  await page.waitForTimeout(5000);
  // Turn on Flutter's semantics tree so elements can be found by text.
  await page.evaluate(() => document.querySelector('flt-semantics-placeholder')?.click());
  await page.waitForTimeout(1500);
  return page;
}

async function run(route, question, name, frames, everyMs) {
  const page = await open(route);
  await page.screenshot({ path: `out/${name}-0-welcome.png` });
  try {
    await page.getByText(question, { exact: false }).first().click({ timeout: 10000 });
    log.push(`[${route}] clicked "${question}"`);
  } catch (e) {
    log.push(`[${route}] could not click "${question}": ${e.message.split('\n')[0]}`);
    const labels = await page.evaluate(() =>
      [...document.querySelectorAll('flt-semantics [aria-label], flt-semantics')]
        .map((n) => (n.getAttribute('aria-label') || n.textContent || '').trim())
        .filter(Boolean).slice(0, 60));
    log.push(`[${route}] semantics labels: ${JSON.stringify(labels)}`);
  }
  for (let i = 1; i <= frames; i++) {
    await page.waitForTimeout(everyMs);
    await page.screenshot({ path: `out/${name}-${String(i).padStart(2, '0')}.png` });
  }
  await page.close();
}

await run('/streaming', 'Write a Dart singleton pattern', 'pin', 45, 250);
await run('/streaming', 'Compare StatelessWidget vs StatefulWidget', 'cmp', 45, 250);
writeFileSync('out/log.txt', log.join('\n') + '\n');
await browser.close();
