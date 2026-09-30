import { chromium } from 'playwright';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const outDir = path.join(__dirname, 'layout-shots');
fs.mkdirSync(outDir, { recursive: true });

const candidates = [
  'https://barbeariaagile.vercel.app/moura',
  'https://barbeariaagile.vercel.app/demo',
  'https://barbeariaagile.vercel.app/',
];

async function waitFlutter(page, ms = 12000) {
  await page.waitForTimeout(ms);
}

async function clickByText(page, text) {
  // Flutter web: try accessibility / DOM text first, then canvas click via semantics
  const clicked = await page.evaluate((label) => {
    const all = Array.from(document.querySelectorAll('*'));
    const el = all.find((n) => (n.innerText || n.textContent || '').trim() === label);
    if (el) {
      el.click();
      return true;
    }
    // flt-semantics
    const sem = Array.from(document.querySelectorAll('flt-semantics, [role], flutter-view *'))
      .find((n) => (n.getAttribute('aria-label') || n.innerText || '').includes(label));
    if (sem) {
      sem.dispatchEvent(new MouseEvent('click', { bubbles: true }));
      return true;
    }
    return false;
  }, text);
  return clicked;
}

const browser = await chromium.launch({ headless: true });
const report = { tried: [], desktop: null, mobile: null };

for (const url of candidates) {
  const page = await browser.newPage({ viewport: { width: 1280, height: 900 } });
  try {
    const res = await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 60000 });
    await waitFlutter(page, 10000);
    const title = await page.title();
    const body = await page.evaluate(() => (document.body?.innerText || '').slice(0, 500));
    const shot = path.join(outDir, `probe_${encodeURIComponent(url)}.png`);
    await page.screenshot({ path: shot, fullPage: false });
    report.tried.push({ url, status: res?.status(), title, body, shot });
  } catch (e) {
    report.tried.push({ url, error: String(e) });
  } finally {
    await page.close();
  }
}

// Prefer first successful with content
const liveUrl =
  report.tried.find((t) => t.body && t.body.length > 20)?.url ||
  report.tried.find((t) => t.status === 200)?.url ||
  candidates[0];

// Desktop Agendar
{
  const page = await browser.newPage({ viewport: { width: 1280, height: 900 } });
  await page.goto(liveUrl, { waitUntil: 'domcontentloaded', timeout: 60000 });
  await waitFlutter(page, 12000);

  // Enable semantics for Flutter web if placeholder present
  await page.evaluate(() => {
    const ph = document.querySelector('flt-semantics-placeholder');
    if (ph) ph.click();
  });
  await page.waitForTimeout(1500);

  // Try clicking Agendar in nav
  let nav = await clickByText(page, 'Agendar');
  if (!nav) {
    // approximate bottom/top nav click positions for Flutter canvas
    // desktop top nav: try mid-top area
    await page.mouse.click(420, 48);
    await page.waitForTimeout(2000);
  } else {
    await page.waitForTimeout(2500);
  }

  const deskShot = path.join(outDir, 'desktop_agendar.png');
  await page.screenshot({ path: deskShot, fullPage: true });
  const deskText = await page.evaluate(() => document.body?.innerText || '');
  report.desktop = { url: liveUrl, shot: deskShot, text: deskText.slice(0, 1200), navClicked: nav };
  await page.close();
}

// Mobile Agendar
{
  const page = await browser.newPage({
    viewport: { width: 390, height: 844 },
    isMobile: true,
    hasTouch: true,
  });
  await page.goto(liveUrl, { waitUntil: 'domcontentloaded', timeout: 60000 });
  await waitFlutter(page, 12000);
  await page.evaluate(() => {
    const ph = document.querySelector('flt-semantics-placeholder');
    if (ph) ph.click();
  });
  await page.waitForTimeout(1500);

  let nav = await clickByText(page, 'Agendar');
  if (!nav) {
    // floating bottom nav ~ second item
    await page.mouse.click(117, 800);
    await page.waitForTimeout(2000);
  } else {
    await page.waitForTimeout(2500);
  }

  const mobShot = path.join(outDir, 'mobile_agendar.png');
  await page.screenshot({ path: mobShot, fullPage: true });
  const mobText = await page.evaluate(() => document.body?.innerText || '');
  report.mobile = { url: liveUrl, shot: mobShot, text: mobText.slice(0, 1200), navClicked: nav };
  await page.close();
}

fs.writeFileSync(path.join(outDir, 'report.json'), JSON.stringify(report, null, 2));
console.log(JSON.stringify(report, null, 2));
await browser.close();
