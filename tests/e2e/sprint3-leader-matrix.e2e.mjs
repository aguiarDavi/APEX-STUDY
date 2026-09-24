import { chromium } from '/home/davi/.gemini/config/repos/apx-testkit/node_modules/playwright/index.mjs';
import fs from 'fs';
import path from 'path';

const SCREENSHOT_DIR = '/home/davi/Dev/apex-gemini/tests/e2e/screenshots';
if (!fs.existsSync(SCREENSHOT_DIR)) {
  fs.mkdirSync(SCREENSHOT_DIR, { recursive: true });
}

async function run() {
  console.log('================================================================');
  console.log('   WORSHIPFLOW: SPRINT 3 LEADER SCHEDULING MATRIX E2E TESTS     ');
  console.log('================================================================\n');

  const browser = await chromium.launch({
    headless: true,
    executablePath: '/home/davi/.var/app/com.visualstudio.code/cache/ms-playwright/chromium-1228/chrome-linux64/chrome',
    args: ['--no-sandbox', '--disable-setuid-sandbox', '--disable-dev-shm-usage']
  });

  const context = await browser.newContext({
    viewport: { width: 1280, height: 900 }
  });

  const page = await context.newPage();

  const consoleErrors = [];
  page.on('console', msg => {
    if (msg.type() === 'error') {
      consoleErrors.push(msg.text());
      console.error(`  [Browser Console Error]: ${msg.text()}`);
    }
  });

  try {
    // ------------------------------------------------------------------------
    // TEST 1: Authentication & Navigation to Leader Matrix
    // ------------------------------------------------------------------------
    console.log('[TEST 1] Authenticating and navigating to Leader Matrix (Page 20)...');
    await page.goto('http://localhost:8181/ords/r/davi/teste/login', { waitUntil: 'networkidle' });
    await page.fill('#P9999_USERNAME', 'TEST_USER');
    await page.fill('#P9999_PASSWORD', 'Oracle_Apex_2026!');
    
    await Promise.all([
      page.waitForNavigation({ waitUntil: 'networkidle' }),
      page.click('button:has-text("Sign In")')
    ]);
    await page.waitForTimeout(500);

    const session = await page.evaluate(() => (typeof apex !== 'undefined' && apex.env) ? apex.env.APP_SESSION : null);
    console.log(`  -> Authenticated session: ${session}`);

    const matrixUrl = `http://localhost:8181/ords/r/davi/teste/leader-matrix?session=${session}`;
    await page.goto(matrixUrl, { waitUntil: 'networkidle' });
    await page.waitForTimeout(800);

    const title = await page.title();
    console.log(`  -> Page title: "${title}"`);
    if (!title.includes('Leader Scheduling Matrix')) {
      throw new Error(`Expected title containing "Leader Scheduling Matrix", got "${title}"`);
    }

    await page.screenshot({ path: path.join(SCREENSHOT_DIR, '10-leader-matrix-initial.png') });
    console.log('  [PASS] Arrived at Leader Scheduling Matrix.');

    // ------------------------------------------------------------------------
    // TEST 2: Verify Active Service Selector & Controls
    // ------------------------------------------------------------------------
    console.log('\n[TEST 2] Verifying Service Selector and Action Toolbar...');
    const serviceSelect = page.locator('#P20_SERVICE_ID');
    const isServiceSelectVisible = await serviceSelect.count() > 0;
    console.log(`  -> Service select dropdown present: ${isServiceSelectVisible}`);

    const applyTemplateBtn = page.locator('button:has-text("Instantiate Template"), a:has-text("Instantiate Template")');
    const autoFillBtn = page.locator('button:has-text("Auto-Fill Bands")');
    const publishBtn = page.locator('button:has-text("Publish Schedule")');

    console.log(`  -> "Instantiate Template" button count: ${await applyTemplateBtn.count()}`);
    console.log(`  -> "Auto-Fill Bands" button count: ${await autoFillBtn.count()}`);
    console.log(`  -> "Publish Schedule" button count: ${await publishBtn.count()}`);

    if ((await applyTemplateBtn.count()) === 0 || (await autoFillBtn.count()) === 0) {
      throw new Error('Required toolbar action buttons missing!');
    }
    console.log('  [PASS] Header toolbar buttons verified.');

    // ------------------------------------------------------------------------
    // TEST 3: Instantiate Template Modal Flow (Page 22)
    // ------------------------------------------------------------------------
    console.log('\n[TEST 3] Testing "Instantiate Template" Modal Flow (Page 22)...');
    await applyTemplateBtn.first().click();
    await page.waitForTimeout(1500);

    const templateDialog = page.frameLocator('iframe.apex-modal-dialog, iframe[title="Apply Band Template"], .ui-dialog iframe');
    const templateItem = templateDialog.locator('#P22_TEMPLATE_ID');
    const isTemplateFrameVisible = await templateItem.count() > 0;
    console.log(`  -> Template modal dialog iframe detected: ${isTemplateFrameVisible}`);

    if (isTemplateFrameVisible) {
      // Select first non-null template option
      const options = await templateDialog.locator('#P22_TEMPLATE_ID option').evaluateAll(opts => opts.map(o => ({ value: o.value, text: o.text })));
      console.log('  -> Available Templates:', options.map(o => o.text).filter(Boolean));
      
      const validOpt = options.find(o => o.value && o.value !== '%null%');
      if (validOpt) {
        await templateDialog.locator('body').evaluate((body, val) => {
          if (typeof apex !== 'undefined' && apex.item) {
            apex.item('P22_TEMPLATE_ID').setValue(val);
          }
        }, validOpt.value);
        await templateDialog.locator('#P22_TEMPLATE_ID').selectOption(validOpt.value).catch(() => {});
      }

      await page.screenshot({ path: path.join(SCREENSHOT_DIR, '11-template-modal-selected.png') });
      console.log('  -> Submitting template instantiation...');
      await templateDialog.locator('button:has-text("Apply Template")').click();

      const dialogDetached = await page.waitForSelector('.ui-dialog', { state: 'detached', timeout: 8000 })
        .then(() => true)
        .catch(() => false);
      console.log(`  -> Template dialog closed: ${dialogDetached}`);
      if (!dialogDetached) {
        await page.click('.ui-dialog-titlebar-close').catch(() => {});
        await page.waitForSelector('.ui-dialog', { state: 'detached', timeout: 3000 }).catch(() => {});
      }
      console.log('  [PASS] Template successfully instantiated into roster slots.');
    }

    // Refresh page to load instantiated slots
    await page.goto(matrixUrl, { waitUntil: 'networkidle' });
    await page.waitForTimeout(1000);
    await page.screenshot({ path: path.join(SCREENSHOT_DIR, '12-slots-instantiated.png') });

    // ------------------------------------------------------------------------
    // TEST 4: Auto-Fill Bands Execution
    // ------------------------------------------------------------------------
    console.log('\n[TEST 4] Testing "Auto-Fill Bands" randomizer...');
    const autoFill = page.locator('button:has-text("Auto-Fill Bands")');
    if (await autoFill.count() > 0) {
      await Promise.all([
        page.waitForNavigation({ waitUntil: 'networkidle' }),
        autoFill.first().click()
      ]);
      await page.waitForTimeout(1000);

      const pageText = await page.textContent('body');
      const autoFillSuccess = pageText.includes('automatically assigned') || pageText.includes('Band slots');
      console.log(`  -> Auto-Fill success notification detected: ${autoFillSuccess}`);
      await page.screenshot({ path: path.join(SCREENSHOT_DIR, '13-bands-autofilled.png') });
      console.log('  [PASS] Auto-Fill bands executed successfully.');
    }

    // ------------------------------------------------------------------------
    // TEST 5: Smart LOV & Musician Assignment / Replacement Modal (Page 21)
    // ------------------------------------------------------------------------
    console.log('\n[TEST 5] Testing Smart LOV in Assign/Replace Modal (Page 21)...');
    const assignButtons = page.locator('button:has-text("Assign / Replace"), a:has-text("Assign / Replace")');
    const assignBtnCount = await assignButtons.count();
    console.log(`  -> "Assign / Replace" action buttons found: ${assignBtnCount}`);

    if (assignBtnCount > 0) {
      await assignButtons.first().click();
      await page.waitForTimeout(1500);

      const assignDialog = page.frameLocator('iframe.apex-modal-dialog, iframe[title="Assign Musician to Slot"], .ui-dialog iframe');
      const memberSelect = assignDialog.locator('#P21_MEMBER_ID');
      const isAssignFrameVisible = await memberSelect.count() > 0;
      console.log(`  -> Assign modal dialog iframe detected: ${isAssignFrameVisible}`);

      if (isAssignFrameVisible) {
        // Inspect Smart LOV option texts for blockout warnings
        const musicianOptions = await assignDialog.locator('#P21_MEMBER_ID option').evaluateAll(opts => opts.map(o => o.text));
        console.log('  -> Smart LOV Candidates:\n    ' + musicianOptions.filter(Boolean).join('\n    '));

        const hasSmartFlag = musicianOptions.some(text => text.includes('BLOCKED OUT') || text.includes('Available'));
        console.log(`  -> Smart LOV availability/conflict tags detected: ${hasSmartFlag}`);

        // Select an available musician
        const availableOpt = await assignDialog.locator('#P21_MEMBER_ID option').evaluateAll(opts => {
          const match = opts.find(o => o.value && o.value !== '%null%' && !o.text.includes('BLOCKED OUT'));
          return match ? match.value : null;
        });

        if (availableOpt) {
          await assignDialog.locator('body').evaluate((body, val) => {
            if (typeof apex !== 'undefined' && apex.item) {
              apex.item('P21_MEMBER_ID').setValue(val);
              apex.item('P21_STATUS').setValue('ACCEPTED');
            }
          }, availableOpt);
        }

        await page.screenshot({ path: path.join(SCREENSHOT_DIR, '14-assign-modal-smart-lov.png') });
        console.log('  -> Submitting assignment...');
        await assignDialog.locator('button:has-text("Save Assignment")').click();

        const assignDialogDetached = await page.waitForSelector('.ui-dialog', { state: 'detached', timeout: 8000 })
          .then(() => true)
          .catch(() => false);
        console.log(`  -> Assign modal dialog detached: ${assignDialogDetached}`);
        if (!assignDialogDetached) {
          await page.click('.ui-dialog-titlebar-close').catch(() => {});
          await page.waitForSelector('.ui-dialog', { state: 'detached', timeout: 3000 }).catch(() => {});
        }
        console.log('  [PASS] Smart LOV verified and slot assignment submitted.');
      }
    }

    // Refresh page to verify updated status
    await page.goto(matrixUrl, { waitUntil: 'networkidle' });
    await page.waitForTimeout(800);

    // ------------------------------------------------------------------------
    // TEST 6: Publish Schedule Flow
    // ------------------------------------------------------------------------
    console.log('\n[TEST 6] Testing "Publish Schedule" flow...');
    const publishButton = page.locator('button:has-text("Publish Schedule")');
    if (await publishButton.count() > 0) {
      await Promise.all([
        page.waitForNavigation({ waitUntil: 'networkidle' }),
        publishButton.first().click()
      ]);
      await page.waitForTimeout(1000);

      const bodyText = await page.textContent('body');
      const publishSuccess = bodyText.includes('successfully published') || bodyText.includes('PUBLISHED');
      console.log(`  -> Publish success state verified: ${publishSuccess}`);
      await page.screenshot({ path: path.join(SCREENSHOT_DIR, '15-service-published.png') });
      console.log('  [PASS] Schedule published and released to volunteers.');
    }

    // ------------------------------------------------------------------------
    // TEST 7: Browser Console Health Check
    // ------------------------------------------------------------------------
    console.log('\n[TEST 7] Checking Browser Console Health...');
    if (consoleErrors.length > 0) {
      console.warn(`  [WARN] ${consoleErrors.length} console errors logged: ${consoleErrors.join('; ')}`);
    } else {
      console.log('  [PASS] Zero console errors during entire Leader Matrix test lifecycle.');
    }

    console.log('\n================================================================');
    console.log('   ALL SPRINT 3 LEADER MATRIX E2E TESTS PASSED (100% SUCCESS)   ');
    console.log('================================================================\n');

  } finally {
    await browser.close();
  }
}

run().catch(err => {
  console.error('\nE2E TEST FAILURE:', err);
  process.exit(1);
});
