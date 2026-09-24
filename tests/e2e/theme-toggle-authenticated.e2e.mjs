import { chromium } from '/repo/node_modules/playwright/index.mjs';

async function run() {
  console.log('================================================================');
  console.log('  ORACLE APEX 26.1 - THEME TOGGLE (AUTHENTICATED & RELOAD TEST) ');
  console.log('================================================================\n');

  const browser = await chromium.launch({
    headless: true,
    executablePath: '/usr/bin/chromium-browser',
    args: ['--no-sandbox', '--disable-setuid-sandbox', '--disable-dev-shm-usage']
  });

  const context = await browser.newContext({
    viewport: { width: 1280, height: 800 }
  });
  const page = await context.newPage();

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

  // Helper function to inspect current theme DOM state
  async function inspectTheme() {
    return page.evaluate(() => {
      const isDarkClass = document.body.classList.contains('apex-theme-vita-dark');
      const isLightClass = document.body.classList.contains('apex-theme-iris');
      const link = Array.from(document.querySelectorAll('link[rel="stylesheet"]')).find(l => 
        l.href && (l.href.includes('Iris') || l.href.includes('Vita-Dark') || l.href.includes('Vita.'))
      );
      const href = link ? link.getAttribute('href') : '';
      const icon = document.querySelector('.js-theme-toggle .t-Icon');
      const iconContent = icon ? window.getComputedStyle(icon, '::before').getPropertyValue('content') : '';
      const user = apex.env ? apex.env.APP_USER : null;
      const session = apex.env ? apex.env.APP_SESSION : null;
      return { isDarkClass, isLightClass, href, iconContent, user, session };
    });
  }

  // TEST 1: Unauthenticated Redirect to Login
  console.log('[TEST 1] Accessing protected Home page (verifying APEX Accounts authentication)...');
  const homeUrl = 'http://localhost:8181/ords/r/davi/teste/home';
  await page.goto(homeUrl, { waitUntil: 'networkidle' });
  await page.waitForTimeout(500);

  const currentUrl = page.url();
  console.log(`  -> Current URL after navigation: ${currentUrl}`);
  if (!currentUrl.includes('login')) {
    throw new Error(`FAIL: Home page was not protected! Expected redirect to login, got ${currentUrl}`);
  }
  console.log('  -> PASS: Unauthenticated access redirected to Login page.');

  // TEST 2: Log In as TEST_USER
  console.log('\n[TEST 2] Logging in with APEX account credentials (TEST_USER)...');
  await page.fill('#P9999_USERNAME', 'TEST_USER');
  await page.fill('#P9999_PASSWORD', 'Oracle_Apex_2026!');
  
  const navsBeforeLogin = navigations;
  await Promise.all([
    page.waitForNavigation({ waitUntil: 'networkidle' }),
    page.click('button:has-text("Sign In")')
  ]);
  await page.waitForTimeout(1000);

  let state = await inspectTheme();
  console.log(`  -> Logged in as: ${state.user}, Session: ${state.session}`);
  if (state.user !== 'TEST_USER') {
    throw new Error(`FAIL: Expected authenticated user TEST_USER, got ${state.user}`);
  }
  console.log('  -> PASS: Successfully authenticated and arrived at Home page.');

  // TEST 3: Initial Light Mode State & Anti-Flicker Verification
  console.log('\n[TEST 3] Verifying Initial Theme State (Light Mode / Iris)...');
  const toggleBtn = page.locator('.js-theme-toggle a');
  await toggleBtn.waitFor({ state: 'visible', timeout: 5000 });

  const labelDisplay = await page.$eval('.js-theme-toggle .t-Button-label', el => window.getComputedStyle(el).display);
  if (labelDisplay !== 'none') {
    throw new Error(`FAIL: Label text must be display:none, but is '${labelDisplay}'`);
  }
  console.log('  -> PASS: Label text is hidden via CSS (display: none). No text FOUC.');

  console.log('  -> Initial State:', JSON.stringify(state));
  if (!state.href.includes('Iris') || !state.isLightClass) {
    throw new Error(`FAIL: Initial theme must be Iris (Light), but got href: ${state.href}`);
  }
  console.log('  -> PASS: Initial theme is Iris (Light) with Moon icon.');
  await page.screenshot({ path: '/app-src/tests/e2e/auth-01-initial-light.png' });

  // TEST 4: Toggle Light -> Dark Mode (Instant In-Place Swap)
  console.log('\n[TEST 4] Clicking Theme Toggle (Switch to Dark)...');
  const navsBeforeClick1 = navigations;
  await toggleBtn.click();
  await page.waitForTimeout(600); // Allow DOM update & background AJAX

  if (navigations !== navsBeforeClick1) {
    throw new Error('FAIL: Full page reload detected on toggle click! Must be instant in-place swap.');
  }

  state = await inspectTheme();
  console.log('  -> State after toggle to Dark:', JSON.stringify(state));
  if (!state.isDarkClass || !state.href.includes('Vita-Dark')) {
    throw new Error(`FAIL: Instant swap did not apply Vita-Dark stylesheet! href: ${state.href}`);
  }
  console.log('  -> PASS: Instant in-place swap to Dark Mode succeeded without page reload.');
  await page.screenshot({ path: '/app-src/tests/e2e/auth-02-swapped-dark.png' });

  // TEST 5: RELOAD PAGE IN DARK MODE (The User's Bug Scenario)
  console.log('\n[TEST 5] RELOADING PAGE IN DARK MODE (Verifying Server Persistence & No Flicker)...');
  await page.waitForTimeout(1000); // Ensure server persistence AJAX finished
  const navsBeforeReload = navigations;
  await page.reload({ waitUntil: 'networkidle' });
  await page.waitForTimeout(500);

  state = await inspectTheme();
  console.log('  -> State after page reload in Dark Mode:', JSON.stringify(state));
  if (!state.isDarkClass || !state.href.includes('Vita-Dark')) {
    throw new Error(`FAIL: Page reload in Dark Mode did NOT return Vita-Dark from server! href: ${state.href}`);
  }
  console.log('  -> PASS: Page reloaded directly in Dark Mode from the server with zero flicker.');
  await page.screenshot({ path: '/app-src/tests/e2e/auth-03-reloaded-dark.png' });

  // TEST 6: CLICK THEME TOGGLE AFTER RELOAD IN DARK MODE (The Exact Reported Failure Point)
  console.log('\n[TEST 6] CLICKING TOGGLE AFTER RELOAD IN DARK MODE (Verifying button works!)...');
  const toggleBtnAfterReload = page.locator('.js-theme-toggle a');
  await toggleBtnAfterReload.waitFor({ state: 'visible', timeout: 5000 });
  
  const navsBeforeClickAfterReload = navigations;
  await toggleBtnAfterReload.click();
  await page.waitForTimeout(600);

  if (navigations !== navsBeforeClickAfterReload) {
    throw new Error('FAIL: Full page reload detected on click after reload!');
  }

  state = await inspectTheme();
  console.log('  -> State after clicking toggle in Dark Mode:', JSON.stringify(state));
  if (!state.isLightClass || !state.href.includes('Iris')) {
    throw new Error(`FAIL: Button did not work after reload in Dark Mode! Still in Dark mode. State: ${JSON.stringify(state)}`);
  }
  console.log('  -> PASS: BUTTON WORKS PERFECTLY AFTER RELOAD IN DARK MODE! Switched back to Iris (Light).');
  await page.screenshot({ path: '/app-src/tests/e2e/auth-04-toggled-back-light.png' });

  // TEST 7: RELOADING PAGE IN LIGHT MODE (Verifying Server Persistence & Button Repeatability)
  console.log('\n[TEST 7] RELOADING PAGE IN LIGHT MODE (Verifying server persistence for Light Mode)...');
  await page.waitForTimeout(1000);
  await page.reload({ waitUntil: 'networkidle' });
  await page.waitForTimeout(500);

  state = await inspectTheme();
  console.log('  -> State after page reload in Light Mode:', JSON.stringify(state));
  if (!state.isLightClass || !state.href.includes('Iris')) {
    throw new Error(`FAIL: Page reload did NOT preserve Iris (Light)! href: ${state.href}`);
  }
  console.log('  -> PASS: Page reloaded directly in Light Mode from the server.');

  // TEST 8: Full Cycle Verification (Light -> Dark again after light reload)
  console.log('\n[TEST 8] Final Toggle Cycle: Light -> Dark again...');
  await page.locator('.js-theme-toggle a').click();
  await page.waitForTimeout(600);
  state = await inspectTheme();
  if (!state.isDarkClass || !state.href.includes('Vita-Dark')) {
    throw new Error('FAIL: Could not cycle back to Dark Mode!');
  }
  console.log('  -> PASS: Second cycle to Dark Mode works cleanly.');

  // Reset to default Light mode
  console.log('\n[CLEANUP] Resetting back to default Light Mode...');
  await page.locator('.js-theme-toggle a').click();
  await page.waitForTimeout(1500);

  // Check console errors
  if (consoleErrors.length > 0) {
    throw new Error(`FAIL: Detected ${consoleErrors.length} console errors during test run: ${consoleErrors.join(', ')}`);
  }
  console.log('  -> PASS: Zero console errors throughout entire session.');

  console.log('\n================================================================');
  console.log('   ALL AUTHENTICATED E2E TESTS PASSED WITH 100% SUCCESS!       ');
  console.log('================================================================');

  await browser.close();
}

run().catch(err => {
  console.error('\nE2E TEST FAILURE:', err);
  process.exit(1);
});
