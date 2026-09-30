import { chromium } from 'playwright';
import fs from 'fs';
import path from 'path';
const outDir = process.argv[2];
const urls = [
  'https://barbeariaagile.vercel.app',
  'https://barbeariaagile.vercel.app/?slug=demo',
  'https://barbeariaagile.vercel.app/demo',
  'https://barbeariaagile.vercel.app/sucesso-assinatura',
];
const browser = await chromium.launch({ headless: true });
const page = await browser.newPage({ viewport: { width: 1280, height: 800 } });
const report = { urls: [] };
for (const url of urls) {
  const entry = { url, ok: false };
  try {
    const resp = await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 60000 });
    entry.status = resp?.status();
    await page.waitForTimeout(5000);
    entry.title = await page.title();
    entry.bodyPreview = await page.evaluate(() => (document.body?.innerText || '').slice(0, 800));
    const dom = await page.evaluate(() => {
      const canvases = document.querySelectorAll('canvas');
      const flutter = document.querySelector('flt-glass-pane, flt-scene-host, meta[name="flutterweb_renderer"]');
      return {
        canvasCount: canvases.length,
        canvasInfo: Array.from(canvases).slice(0, 5).map(c => ({ width: c.width, height: c.height, id: c.id, className: String(c.className) })),
        hasFlutterMeta: !!document.querySelector('meta[name="flutterweb_renderer"]'),
        hasFlutterTags: !!flutter,
        scriptCount: document.scripts.length,
        bodyChildTags: Array.from(document.body?.children || []).slice(0, 10).map(el => el.tagName.toLowerCase()),
      };
    });
    entry.dom = dom;
    entry.isFlutterCanvas = dom.canvasCount > 0 || dom.hasFlutterMeta || dom.hasFlutterTags;
    const safe = url.replace(/[^a-z0-9]+/gi, '_').slice(0, 60);
    const shot = path.join(outDir, safe + '.png');
    await page.screenshot({ path: shot, fullPage: false });
    entry.screenshot = shot;
    entry.ok = true;
  } catch (e) {
    entry.error = String(e.message || e);
  }
  report.urls.push(entry);
}
try {
  await page.goto('https://barbeariaagile.vercel.app', { waitUntil: 'domcontentloaded', timeout: 60000 });
  await page.waitForTimeout(2000);
  report.injectionPreflight = await page.evaluate(() => {
    try {
      const s = document.createElement('script');
      s.textContent = 'window.__impeccable_probe = 1';
      document.head.appendChild(s);
      return { mutableInjection: window.__impeccable_probe === 1 };
    } catch (e) {
      return { mutableInjection: false, error: String(e) };
    }
  });
  const root = report.urls[0];
  report.detectJsInjection = {
    attempted: false,
    skipped: root?.isFlutterCanvas,
    reason: root?.isFlutterCanvas ? 'Flutter Web canvas/raster UI — DOM overlay detect.js not applicable for Assessment B' : 'not skipped by flutter rule',
  };
} catch (e) {
  report.injectionPreflight = { error: String(e) };
}
fs.writeFileSync(path.join(outDir, 'browser-report.json'), JSON.stringify(report, null, 2));
console.log(JSON.stringify(report, null, 2));
await browser.close();
