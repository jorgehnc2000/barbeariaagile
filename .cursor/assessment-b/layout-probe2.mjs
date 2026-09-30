import { chromium } from 'playwright';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const outDir = path.join(__dirname, 'layout-shots');
fs.mkdirSync(outDir, { recursive: true });

async function enableSemantics(page) {
  await page.evaluate(() => {
    const ph = document.querySelector('flt-semantics-placeholder');
    if (ph instanceof HTMLElement) ph.click();
  });
  await page.waitForTimeout(1200);
}

async function dumpSemantics(page) {
  return page.evaluate(() => {
    const nodes = Array.from(document.querySelectorAll('[aria-label], flt-semantics, [role="button"], [role="tab"]'));
    return nodes.slice(0, 80).map((n) => ({
      tag: n.tagName,
      role: n.getAttribute('role'),
      label: n.getAttribute('aria-label'),
      text: (n.innerText || '').slice(0, 80),
      rect: (() => {
        const r = n.getBoundingClientRect();
        return { x: Math.round(r.x), y: Math.round(r.y), w: Math.round(r.width), h: Math.round(r.height) };
      })(),
    }));
  });
}

async function clickLabel(page, label) {
  const hit = await page.evaluate((want) => {
    const nodes = Array.from(document.querySelectorAll('[aria-label], flt-semantics, [role="button"], [role="tab"], [role="link"]'));
    const n = nodes.find((el) => {
      const a = el.getAttribute('aria-label') || '';
      const t = el.innerText || '';
      return a.includes(want) || t.trim() === want || t.includes(want);
    });
    if (!n) return null;
    const r = n.getBoundingClientRect();
    n.dispatchEvent(new MouseEvent('click', { bubbles: true, clientX: r.x + r.width / 2, clientY: r.y + r.height / 2 }));
    return { x: r.x + r.width / 2, y: r.y + r.height / 2, label: n.getAttribute('aria-label') || n.innerText };
  }, label);
  if (hit) {
    await page.mouse.click(hit.x, hit.y);
    return hit;
  }
  return null;
}

const browser = await chromium.launch({ channel: 'chrome', headless: true });
const report = {};

// Desktop
{
  const page = await browser.newPage({ viewport: { width: 1280, height: 900 } });
  await page.goto('https://barbeariaagile.vercel.app/moura', {
    waitUntil: 'domcontentloaded',
    timeout: 60000,
  });
  await page.waitForTimeout(12000);
  await enableSemantics(page);
  let sem = await dumpSemantics(page);
  fs.writeFileSync(path.join(outDir, 'desktop_sem_home.json'), JSON.stringify(sem, null, 2));

  let hit = await clickLabel(page, 'Agendar');
  if (!hit) {
    // try top nav approximate positions for 4-5 tabs
    for (const x of [280, 360, 440, 520, 600]) {
      await page.mouse.click(x, 52);
      await page.waitForTimeout(1500);
      await page.screenshot({ path: path.join(outDir, `desktop_try_x${x}.png`) });
    }
  } else {
    await page.waitForTimeout(3000);
  }
  await enableSemantics(page);
  sem = await dumpSemantics(page);
  fs.writeFileSync(path.join(outDir, 'desktop_sem_after.json'), JSON.stringify(sem, null, 2));
  await page.screenshot({ path: path.join(outDir, 'desktop_after_nav.png'), fullPage: true });
  report.desktopHit = hit;

  // scroll down a bit for schedule panel
  await page.mouse.wheel(0, 600);
  await page.waitForTimeout(800);
  await page.screenshot({ path: path.join(outDir, 'desktop_scrolled.png'), fullPage: false });
  await page.close();
}

// Mobile
{
  const page = await browser.newPage({
    viewport: { width: 390, height: 844 },
    isMobile: true,
    hasTouch: true,
  });
  await page.goto('https://barbeariaagile.vercel.app/moura', {
    waitUntil: 'domcontentloaded',
    timeout: 60000,
  });
  await page.waitForTimeout(12000);
  await enableSemantics(page);
  let sem = await dumpSemantics(page);
  fs.writeFileSync(path.join(outDir, 'mobile_sem_home.json'), JSON.stringify(sem, null, 2));

  let hit = await clickLabel(page, 'Agendar');
  if (!hit) {
    // bottom nav: Início, Agendar, Agenda, VIP?, Perfil — ~5 items
    for (const x of [39, 117, 195, 273, 351]) {
      await page.mouse.click(x, 800);
      await page.waitForTimeout(1600);
      await page.screenshot({ path: path.join(outDir, `mobile_try_x${x}.png`) });
    }
  } else {
    await page.waitForTimeout(3000);
  }
  await enableSemantics(page);
  sem = await dumpSemantics(page);
  fs.writeFileSync(path.join(outDir, 'mobile_sem_after.json'), JSON.stringify(sem, null, 2));
  await page.screenshot({ path: path.join(outDir, 'mobile_after_nav.png'), fullPage: true });
  report.mobileHit = hit;
  await page.mouse.wheel(0, 700);
  await page.waitForTimeout(800);
  await page.screenshot({ path: path.join(outDir, 'mobile_scrolled.png'), fullPage: false });
  await page.close();
}

fs.writeFileSync(path.join(outDir, 'report2.json'), JSON.stringify(report, null, 2));
console.log(JSON.stringify(report, null, 2));
await browser.close();
