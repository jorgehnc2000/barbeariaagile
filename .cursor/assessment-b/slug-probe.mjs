import { chromium } from 'playwright';
const slugs = ['moura','barbearia-moura','barbeariamoura','agile'];
const browser = await chromium.launch({ headless: true });
const page = await browser.newPage({ viewport: { width: 1280, height: 800 } });
for (const slug of slugs) {
  const url = `https://barbeariaagile.vercel.app/${slug}`;
  await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 60000 });
  await page.waitForTimeout(4000);
  const title = await page.title();
  const text = await page.evaluate(() => (document.body?.innerText || '').slice(0, 200));
  console.log(slug, title, JSON.stringify(text));
}
await browser.close();
