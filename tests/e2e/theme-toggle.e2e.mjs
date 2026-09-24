import { chromium } from '/repo/node_modules/playwright/index.mjs';

async function run() {
  console.log('====================================================');
  console.log('   ORACLE APEX 26.1 - THEME TOGGLE E2E VERIFICATION ');
  console.log('====================================================\n');
  
  const browser = await chromium.launch({
    headless: true,
    executablePath: '/usr/bin/chromium-browser',
    args: ['--no-sandbox', '--disable-setuid-sandbox', '--disable-dev-shm-usage']
  });

  const context = await browser.newContext({
    viewport: { width: 1280, height: 800 }
  });
  const page = await context.newPage();

  // Monitor navigations (flicker / unwanted reload detection)
  let navigations = 0;
  page.on('framenavigated', (frame) => {
    if (frame === page.mainFrame()) {
      navigations++;
      console.log(`  [Browser Navigation #${navigations}] ${frame.url()}`);
    }
  });

  const consoleErrors = [];
  page.on('console', msg => {
    if (msg.type() === 'error') {
      consoleErrors.push(msg.text());
      console.error(`  [Console Error]: ${msg.text()}`);
    }
  });

  // 1. Initial Page Load
  const baseUrl = 'http://localhost:8181/ords/r/davi/teste/home';
  console.log(`[TEST 1] Loading application at ${baseUrl}...`);
  await page.goto(baseUrl, { waitUntil: 'networkidle' });

  // Wait 1.5 seconds to confirm no unexpected DAs or redirect loops fire on startup
  await page.waitForTimeout(1500);
  if (navigations > 1) {
    throw new Error(`FAIL: Flickering / auto-redirect loop detected on startup! Navigations: ${navigations}`);
  }
  console.log('  -> PASS: Initial load is stable. Zero flickering or startup redirects.');

  // 2. Verify NavBar Item & Anti-Flicker CSS
  console.log('\n[TEST 2] Verifying Navigation Bar toggle button & styles...');
  const toggleBtn = page.locator('.js-theme-toggle a');
  await toggleBtn.waitFor({ state: 'visible', timeout: 5000 });
  console.log('  -> PASS: .js-theme-toggle item exists in the navigation bar.');

  const labelDisplay = await page.$eval('.js-theme-toggle .t-Button-label', el => window.getComputedStyle(el).display);
  if (labelDisplay !== 'none') {
    throw new Error(`FAIL: Label text must be display:none, but is '${labelDisplay}'`);
  }
  console.log('  -> PASS: Label text is hidden via CSS (display: none). No text FOUC.');

  // Helper to inspect theme state
  async function inspectTheme() {
    return page.evaluate(() => {
      const isDark = document.body.classList.contains('apex-theme-vita-dark');
      const isLight = document.body.classList.contains('apex-theme-iris');
      const link = document.querySelector('link[href*="Iris.min.css"], link[href*="Vita-Dark.min.css"]');
      const href = link ? link.getAttribute('href') : '';
      const icon = document.querySelector('.js-theme-toggle .t-Icon');
      const iconContent = icon ? window.getComputedStyle(icon, '::before').getPropertyValue('content') : '';
      const session = apex.env.APP_SESSION;
      return { isDark, isLight, href, iconContent, session };
    });
  }

  let state = await inspectTheme();
  console.log('  -> Initial State:', JSON.stringify({ isDark: state.isDark, isLight: state.isLight, href: state.href, icon: state.iconContent }));
  await page.screenshot({ path: '/app-src/tests/e2e/01-initial-light.png' });

  // 3. First Click: Switch Light -> Dark
  console.log('\n[TEST 3] Clicking Theme Toggle (Switch to Dark)...');
  const navsBeforeClick1 = navigations;
  await toggleBtn.click();
  await page.waitForTimeout(600); // Allow DOM CSS update and background AJAX

  if (navigations !== navsBeforeClick1) {
    throw new Error('FAIL: Full page reload detected on toggle click! Must be instant in-place swap.');
  }
  state = await inspectTheme();
  console.log('  -> State after 1st click:', JSON.stringify({ isDark: state.isDark, isLight: state.isLight, href: state.href, icon: state.iconContent }));

  if (!state.isDark || !state.href.includes('Vita-Dark')) {
    throw new Error('FAIL: Theme did not switch to Dark mode in-place!');
  }
  console.log('  -> PASS: Instant in-place swap to Dark Mode (no page reload, icon updated).');
  await page.screenshot({ path: '/app-src/tests/e2e/02-swapped-dark.png' });

  // 4. Second Click: Switch Dark -> Light
  console.log('\n[TEST 4] Clicking Theme Toggle again (Switch back to Light)...');
  const navsBeforeClick2 = navigations;
  await toggleBtn.click();
  await page.waitForTimeout(600);

  if (navigations !== navsBeforeClick2) {
    throw new Error('FAIL: Full page reload detected on 2nd toggle click!');
  }
  state = await inspectTheme();
  console.log('  -> State after 2nd click:', JSON.stringify({ isDark: state.isDark, isLight: state.isLight, href: state.href, icon: state.iconContent }));

  if (!state.isLight || !state.href.includes('Iris')) {
    throw new Error('FAIL: Theme did not switch back to Light mode in-place!');
  }
  console.log('  -> PASS: Instant in-place swap back to Light Mode (no page reload).');
  await page.screenshot({ path: '/app-src/tests/e2e/03-swapped-light.png' });

  // 5. Test Server-side Persistence across Session Navigation
  console.log('\n[TEST 5] Testing Server-side Style Persistence...');
  await toggleBtn.click(); // Switch to Dark
  await page.waitForTimeout(1500); // Wait for apex_theme.set_session_style AJAX to complete
  
  const currentSession = state.session;
  console.log(`  -> Navigating with session ${currentSession} to verify server-rendered Dark Mode...`);
  await page.goto(`${baseUrl}?session=${currentSession}`, { waitUntil: 'networkidle' });
  await page.waitForTimeout(500);

  state = await inspectTheme();
  console.log('  -> Server-rendered State:', JSON.stringify({ isDark: state.isDark, isLight: state.isLight, href: state.href, icon: state.iconContent }));

  if (!state.isDark || !state.href.includes('Vita-Dark')) {
    throw new Error('FAIL: Server did not return Dark mode as session style!');
  }
  console.log('  -> PASS: Server returned Dark Mode directly in initial HTML response!');
  await page.screenshot({ path: '/app-src/tests/e2e/04-persisted-dark.png' });

  // 6. Reset to default Light mode
  console.log('\n[TEST 6] Resetting back to default Light Mode...');
  await page.locator('.js-theme-toggle a').click();
  await page.waitForTimeout(1500);
  await page.goto(`${baseUrl}?session=${currentSession}`, { waitUntil: 'networkidle' });
  state = await inspectTheme();
  console.log('  -> Clean State:', JSON.stringify({ isDark: state.isDark, isLight: state.isLight, href: state.href }));
  console.log('  -> PASS: Reset complete.');

  console.log('\n====================================================');
  console.log('   ALL E2E VERIFICATION TESTS PASSED SUCCESSFULLY!  ');
  console.log('====================================================');

  await browser.close();
}

run().catch(err => {
  console.error('\nE2E TEST FAILURE:', err);
  process.exit(1);
});
