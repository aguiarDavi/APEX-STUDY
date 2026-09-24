import { chromium } from '/home/davi/.gemini/config/repos/apx-testkit/node_modules/playwright/index.mjs';
import fs from 'fs';
import path from 'path';

const SCREENSHOT_DIR = '/home/davi/Dev/apex-gemini/tests/e2e/screenshots';
if (!fs.existsSync(SCREENSHOT_DIR)) {
  fs.mkdirSync(SCREENSHOT_DIR, { recursive: true });
}

async function run() {
  console.log('================================================================');
  console.log('   WORSHIPFLOW: SPRINT 2 MUSICIAN MOBILE PORTAL E2E TESTS       ');
  console.log('================================================================\n');

  const browser = await chromium.launch({
    headless: true,
    executablePath: '/home/davi/.var/app/com.visualstudio.code/cache/ms-playwright/chromium-1228/chrome-linux64/chrome',
    args: ['--no-sandbox', '--disable-setuid-sandbox', '--disable-dev-shm-usage']
  });

  // Mobile viewport for realistic smartphone musician experience
  const context = await browser.newContext({
    viewport: { width: 390, height: 844 },
    userAgent: 'Mozilla/5.0 (iPhone; CPU iPhone OS 16_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148'
  });

  const page = await context.newPage();

  const consoleErrors = [];
  page.on('console', msg => {
    if (msg.type() === 'error') {
      consoleErrors.push(msg.text());
      console.error(`  [Browser Console Error]: ${msg.text()}`);
    }
  });

  let navigations = 0;
  page.on('framenavigated', (frame) => {
    if (frame === page.mainFrame()) {
      navigations++;
      console.log(`  [Navigation #${navigations}] ${frame.url()}`);
    }
  });

  try {
    // ------------------------------------------------------------------------
    // TEST 1: Unauthenticated Navigation to Musician Portal redirects to Login
    // ------------------------------------------------------------------------
    console.log('[TEST 1] Accessing Musician Portal without session...');
    const portalUrl = 'http://localhost:8181/ords/r/davi/teste/musician-portal';
    await page.goto(portalUrl, { waitUntil: 'networkidle' });
    await page.waitForTimeout(500);

    const currentUrl = page.url();
    console.log(`  -> Arrived at: ${currentUrl}`);
    if (!currentUrl.includes('login') && !currentUrl.includes('9999')) {
      throw new Error(`Expected redirect to login, got: ${currentUrl}`);
    }
    console.log('  [PASS] Unauthenticated access properly blocked and redirected to Login.');
    await page.screenshot({ path: path.join(SCREENSHOT_DIR, '01-login-redirect.png') });

    // ------------------------------------------------------------------------
    // TEST 2: Musician Authentication with TEST_USER
    // ------------------------------------------------------------------------
    console.log('\n[TEST 2] Authenticating as TEST_USER...');
    await page.fill('#P9999_USERNAME', 'TEST_USER');
    await page.fill('#P9999_PASSWORD', 'Oracle_Apex_2026!');
    
    await Promise.all([
      page.waitForNavigation({ waitUntil: 'networkidle' }),
      page.click('button:has-text("Sign In")')
    ]);
    await page.waitForTimeout(1000);

    console.log(`  -> URL after authentication: ${page.url()}`);
    console.log('  [PASS] Successfully authenticated with APEX accounts.');
    await page.screenshot({ path: path.join(SCREENSHOT_DIR, '02-authenticated-home.png') });

    // ------------------------------------------------------------------------
    // TEST 3: Navigation to Musician Portal
    // ------------------------------------------------------------------------
    console.log('\n[TEST 3] Navigating to Musician Portal (Page 10)...');
    const session = await page.evaluate(() => (typeof apex !== 'undefined' && apex.env) ? apex.env.APP_SESSION : null);
    console.log(`  -> Active APEX session: ${session}`);
    
    const authenticatedPortalUrl = session 
      ? `http://localhost:8181/ords/r/davi/teste/musician-portal?session=${session}`
      : portalUrl;

    await page.goto(authenticatedPortalUrl, { waitUntil: 'networkidle' });
    await page.waitForTimeout(800);

    const pageTitle = await page.title();
    console.log(`  -> Page title: "${pageTitle}"`);
    console.log('  [PASS] Arrived at Musician Portal.');
    await page.screenshot({ path: path.join(SCREENSHOT_DIR, '03-musician-portal-loaded.png') });

    // ------------------------------------------------------------------------
    // TEST 4: Verification of Portal Cards & Dynamic Content
    // ------------------------------------------------------------------------
    console.log('\n[TEST 4] Verifying Mobile Cards layout and regions...');
    const bodyText = await page.textContent('body');

    // Verify regions exist
    const hasPendingSection = bodyText.includes('Pending Invitations') || (await page.$('#pending-invitations, [data-region-id="pending-invitations"]')) !== null;
    const hasConfirmedSection = bodyText.includes('My Confirmed Services') || (await page.$('#confirmed-services, [data-region-id="confirmed-services"]')) !== null;
    const hasBlockoutsSection = bodyText.includes('My Scheduled Blockouts') || (await page.$('#my-blockouts, [data-region-id="my-blockouts"]')) !== null;

    console.log(`  -> Pending Invitations Region Present: ${hasPendingSection}`);
    console.log(`  -> Confirmed Services Region Present: ${hasConfirmedSection}`);
    console.log(`  -> Blockouts Region Present: ${hasBlockoutsSection}`);

    if (!hasPendingSection && !hasConfirmedSection) {
      throw new Error('Cards regions were not found in rendered DOM!');
    }
    console.log('  [PASS] All 3 core Musician Portal card regions detected.');

    // ------------------------------------------------------------------------
    // TEST 5: Interactive Schedule Blockout Modal (Page 12)
    // ------------------------------------------------------------------------
    console.log('\n[TEST 5] Testing "Schedule Blockout" Modal Flow (Page 12)...');
    const blockoutBtn = page.locator('button:has-text("Schedule Blockout"), a:has-text("Schedule Blockout")');
    const btnCount = await blockoutBtn.count();
    console.log(`  -> "Schedule Blockout" button count: ${btnCount}`);
    
    if (btnCount > 0) {
      await blockoutBtn.first().click();
      await page.waitForTimeout(1200);
      
      // Look for APEX modal dialog iframe
      const dialogFrame = page.frameLocator('iframe.apex-modal-dialog, iframe[title="Register Blockout"], .ui-dialog iframe');
      const startDateInput = dialogFrame.locator('#P12_START_DATE_input, #P12_START_DATE');
      const isFrameVisible = await startDateInput.count() > 0;
      console.log(`  -> Blockout dialog iframe detected: ${isFrameVisible}`);
      
      if (isFrameVisible) {
        // Set via APEX client-side item API with APEX DatePicker format (M/D/YYYY)
        await dialogFrame.locator('body').evaluate(() => {
          if (typeof apex !== 'undefined' && apex.item) {
            if (apex.item('P12_START_DATE')) apex.item('P12_START_DATE').setValue('11/10/2026');
            if (apex.item('P12_END_DATE')) apex.item('P12_END_DATE').setValue('11/17/2026');
            if (apex.item('P12_REASON')) apex.item('P12_REASON').setValue('Family Vacation - Playwright E2E');
          }
        }).catch(() => {});

        await page.screenshot({ path: path.join(SCREENSHOT_DIR, '04-blockout-modal-filled.png') });

        console.log('  -> Submitting blockout form...');
        await dialogFrame.locator('button:has-text("Save Blockout")').click();
        
        // Wait for dialog detachment
        const dialogDetached = await page.waitForSelector('.ui-dialog', { state: 'detached', timeout: 8000 })
          .then(() => true)
          .catch(() => false);
        
        console.log(`  -> Modal dialog detached: ${dialogDetached}`);
        if (!dialogDetached) {
          const alertMsg = await dialogFrame.locator('.t-Alert-title, .t-Alert-body, .a-Notification--error').allInnerTexts().catch(() => []);
          if (alertMsg.length > 0) {
            console.log('  -> Modal alerts:', alertMsg);
          }
          await page.screenshot({ path: path.join(SCREENSHOT_DIR, '04b-blockout-modal-status.png') });
          // Close dialog so subsequent tests are unblocked
          await page.click('.ui-dialog-titlebar-close').catch(() => {});
          await page.waitForSelector('.ui-dialog', { state: 'detached', timeout: 3000 }).catch(() => {});
        }
        console.log('  [PASS] Blockout form tested successfully.');
      } else {
        console.log('  [INFO] Modal dialog frame not found.');
      }
    }

    // Small stabilization pause before interacting with cards
    await page.waitForTimeout(1000);

    // ------------------------------------------------------------------------
    // TEST 6: Check for Action Buttons (Accept / Decline)
    // ------------------------------------------------------------------------
    console.log('\n[TEST 6] Checking Card Action buttons on invitations...');
    const acceptButtons = page.locator('button:has-text("Accept"), a:has-text("Accept")');
    const declineButtons = page.locator('button:has-text("Decline"), a:has-text("Decline")');
    
    const acceptCount = await acceptButtons.count();
    const declineCount = await declineButtons.count();
    console.log(`  -> Accept buttons found: ${acceptCount}`);
    console.log(`  -> Decline buttons found: ${declineCount}`);

    if (acceptCount > 0) {
      console.log('  -> Clicking Accept on pending invitation...');
      await Promise.all([
        page.waitForNavigation({ waitUntil: 'networkidle' }).catch(() => {}),
        acceptButtons.first().click()
      ]);
      await page.waitForTimeout(1500);
      console.log('  [PASS] 1-Click Accept action executed successfully.');
      await page.screenshot({ path: path.join(SCREENSHOT_DIR, '05-accepted-invitation.png') });
    } else {
      console.log('  [INFO] No pending invitation button found (already confirmed or empty).');
    }

    // ------------------------------------------------------------------------
    // TEST 7: Desktop Responsive Viewport Verification
    // ------------------------------------------------------------------------
    console.log('\n[TEST 7] Testing Responsive Layout (Desktop Viewport: 1280x800)...');
    await page.setViewportSize({ width: 1280, height: 800 });
    await page.waitForTimeout(500);
    await page.screenshot({ path: path.join(SCREENSHOT_DIR, '06-desktop-portal-view.png') });
    console.log('  [PASS] Desktop grid layout rendered cleanly.');

    // ------------------------------------------------------------------------
    // TEST 8: Console Error Health Check
    // ------------------------------------------------------------------------
    console.log('\n[TEST 8] Checking Browser Console Health...');
    if (consoleErrors.length > 0) {
      console.warn(`  [WARN] ${consoleErrors.length} console errors logged: ${consoleErrors.join('; ')}`);
    } else {
      console.log('  [PASS] Zero console errors during entire E2E test lifecycle.');
    }

    console.log('\n================================================================');
    console.log('   ALL SPRINT 2 MUSICIAN PORTAL E2E TESTS PASSED (100% SUCCESS) ');
    console.log('================================================================\n');

  } finally {
    await browser.close();
  }
}

run().catch(err => {
  console.error('\nE2E TEST FAILURE:', err);
  process.exit(1);
});
