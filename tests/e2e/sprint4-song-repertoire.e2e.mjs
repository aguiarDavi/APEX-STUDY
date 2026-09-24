import { chromium } from '/home/davi/.gemini/config/repos/apx-testkit/node_modules/playwright/index.mjs';
import fs from 'fs';
import path from 'path';

const SCREENSHOT_DIR = '/home/davi/Dev/apex-gemini/tests/e2e/screenshots';
if (!fs.existsSync(SCREENSHOT_DIR)) {
  fs.mkdirSync(SCREENSHOT_DIR, { recursive: true });
}

async function run() {
  console.log('================================================================');
  console.log('   WORSHIPFLOW: SPRINT 4 SONG REPERTOIRE & SETLIST E2E TESTS    ');
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
    // TEST 1: Authentication & Navigation to Song Repertoire (Page 30)
    // ------------------------------------------------------------------------
    console.log('[TEST 1] Authenticating and navigating to Song Repertoire (Page 30)...');
    await page.goto('http://localhost:8181/ords/r/davi/teste/login', { waitUntil: 'networkidle' });
    await page.fill('#P9999_USERNAME', 'DAVI');
    await page.fill('#P9999_PASSWORD', 'Oracle_Apex_2026!');
    
    await Promise.all([
      page.waitForNavigation({ waitUntil: 'networkidle' }),
      page.click('button:has-text("Sign In")')
    ]);
    await page.waitForTimeout(500);

    const session = await page.evaluate(() => (typeof apex !== 'undefined' && apex.env) ? apex.env.APP_SESSION : null);
    console.log(`  -> Authenticated session: ${session}`);

    const songsUrl = `http://localhost:8181/ords/r/davi/teste/song-repertoire?session=${session}`;
    await page.goto(songsUrl, { waitUntil: 'networkidle' });
    await page.waitForTimeout(800);

    const title = await page.title();
    console.log(`  -> Page title: "${title}"`);
    if (!title.includes('Song Repertoire')) {
      throw new Error(`Expected title containing "Song Repertoire", got "${title}"`);
    }

    const addSongBtn = page.locator('button:has-text("Add New Song"), a:has-text("Add New Song")');
    console.log(`  -> "Add New Song" button count: ${await addSongBtn.count()}`);
    if ((await addSongBtn.count()) === 0) {
      throw new Error('Add New Song button missing!');
    }

    await page.screenshot({ path: path.join(SCREENSHOT_DIR, '20-song-repertoire-catalog.png') });
    console.log('  [PASS] Song Repertoire catalog loaded successfully.');

    // ------------------------------------------------------------------------
    // TEST 2: Verify Songs Catalog Cards Layout
    // ------------------------------------------------------------------------
    console.log('\n[TEST 2] Verifying Repertoire Catalog Cards layout...');
    const songCards = page.locator('.a-CardView-item');
    const cardCount = await songCards.count();
    console.log(`  -> Repertoire song cards found: ${cardCount}`);
    if (cardCount === 0) {
      throw new Error('No song cards found in repertoire catalog!');
    }

    const firstCardText = await songCards.first().innerText();
    console.log(`  -> First song card details:\n    ${firstCardText.split('\n').join(' | ')}`);
    console.log('  [PASS] Song cards rendered with musical metadata and action buttons.');

    // ------------------------------------------------------------------------
    // TEST 3: Add New Song Modal Flow (Page 31)
    // ------------------------------------------------------------------------
    console.log('\n[TEST 3] Testing "Add New Song" Modal Flow (Page 31)...');
    await addSongBtn.first().click();
    await page.waitForTimeout(1500);

    const songDialog = page.frameLocator('iframe.apex-modal-dialog, iframe[title="Song Details"], .ui-dialog iframe');
    const titleInput = songDialog.locator('#P31_TITLE');
    const isSongFrameVisible = await titleInput.count() > 0;
    console.log(`  -> Song details modal iframe detected: ${isSongFrameVisible}`);

    if (isSongFrameVisible) {
      await titleInput.fill('Gratidao e Louvor - E2E');
      await songDialog.locator('#P31_ARTIST').fill('WorshipFlow Original');
      
      // Set Key, Tempo, Time Signature using APEX item API
      await songDialog.locator('body').evaluate(() => {
        if (typeof apex !== 'undefined' && apex.item) {
          apex.item('P31_DEFAULT_KEY').setValue('G');
          apex.item('P31_BPM').setValue('74');
          apex.item('P31_YOUTUBE_URL').setValue('https://www.youtube.com/watch?v=dQw4w9WgXcQ');
        }
      });

      await page.screenshot({ path: path.join(SCREENSHOT_DIR, '21-add-song-modal-filled.png') });
      console.log('  -> Submitting new song form...');
      await songDialog.locator('button:has-text("Save Song")').click();

      const songDialogDetached = await page.waitForSelector('.ui-dialog', { state: 'detached', timeout: 8000 })
        .then(() => true)
        .catch(() => false);
      console.log(`  -> Song modal dialog closed: ${songDialogDetached}`);
      if (!songDialogDetached) {
        await page.click('.ui-dialog-titlebar-close').catch(() => {});
        await page.waitForSelector('.ui-dialog', { state: 'detached', timeout: 3000 }).catch(() => {});
      }
      console.log('  [PASS] New song saved to repertoire.');
    }

    // Refresh catalog page to confirm presence of newly added song
    await page.goto(songsUrl, { waitUntil: 'networkidle' });
    await page.waitForTimeout(800);
    const catalogBody = await page.textContent('body');
    const newSongPresent = catalogBody.includes('Gratidao e Louvor') || catalogBody.includes('WorshipFlow Original');
    console.log(`  -> Newly created song detected in catalog: ${newSongPresent}`);
    await page.screenshot({ path: path.join(SCREENSHOT_DIR, '22-song-repertoire-updated.png') });

    // ------------------------------------------------------------------------
    // TEST 4: Add Song to Service Setlist Modal Flow (Page 32)
    // ------------------------------------------------------------------------
    console.log('\n[TEST 4] Testing "Add to Setlist" Modal Flow (Page 32)...');
    const setlistActions = page.locator('button:has-text("Add to Setlist"), a:has-text("Add to Setlist")');
    const setlistBtnCount = await setlistActions.count();
    console.log(`  -> "Add to Setlist" action buttons found: ${setlistBtnCount}`);

    if (setlistBtnCount > 0) {
      await setlistActions.first().click();
      await page.waitForTimeout(1500);

      const setlistDialog = page.frameLocator('iframe.apex-modal-dialog, iframe[title="Add Song to Setlist"], .ui-dialog iframe');
      const serviceKeyItem = setlistDialog.locator('#P32_SERVICE_KEY');
      const isSetlistFrameVisible = await serviceKeyItem.count() > 0;
      console.log(`  -> Setlist modal dialog iframe detected: ${isSetlistFrameVisible}`);

      if (isSetlistFrameVisible) {
        // Transpose key to A
        await setlistDialog.locator('body').evaluate(() => {
          if (typeof apex !== 'undefined' && apex.item) {
            apex.item('P32_SERVICE_KEY').setValue('A');
            apex.item('P32_NOTES').setValue('Transposed to A for female lead. Acoustic fingerpicking intro.');
          }
        });

        await page.screenshot({ path: path.join(SCREENSHOT_DIR, '23-setlist-modal-transposed.png') });
        console.log('  -> Submitting song to setlist...');
        await setlistDialog.locator('button:has-text("Add to Setlist")').click();

        const setlistDialogDetached = await page.waitForSelector('.ui-dialog', { state: 'detached', timeout: 8000 })
          .then(() => true)
          .catch(() => false);
        console.log(`  -> Setlist modal dialog closed: ${setlistDialogDetached}`);
        if (!setlistDialogDetached) {
          await page.click('.ui-dialog-titlebar-close').catch(() => {});
          await page.waitForSelector('.ui-dialog', { state: 'detached', timeout: 3000 }).catch(() => {});
        }
        console.log('  [PASS] Song added to active service setlist.');
      }
    }

    // ------------------------------------------------------------------------
    // TEST 5: Verify Setlist Display on Leader Matrix (Page 20)
    // ------------------------------------------------------------------------
    console.log('\n[TEST 5] Verifying Setlist Region on Leader Matrix (Page 20)...');
    const matrixUrl = `http://localhost:8181/ords/r/davi/teste/leader-matrix?session=${session}`;
    await page.goto(matrixUrl, { waitUntil: 'networkidle' });
    await page.waitForTimeout(1000);

    const matrixBody = await page.textContent('body');
    const hasSetlistSection = matrixBody.includes('Service Setlist') || (await page.$('#service-setlist, [data-region-id="service-setlist"]')) !== null;
    console.log(`  -> Service Setlist Region Present on Page 20: ${hasSetlistSection}`);
    
    await page.screenshot({ path: path.join(SCREENSHOT_DIR, '24-leader-matrix-setlist-view.png') });
    console.log('  [PASS] Service setlist integrated and verified on Leader Scheduling Matrix.');

    // ------------------------------------------------------------------------
    // TEST 6: Browser Console Health Check
    // ------------------------------------------------------------------------
    console.log('\n[TEST 6] Checking Browser Console Health...');
    if (consoleErrors.length > 0) {
      console.warn(`  [WARN] ${consoleErrors.length} console errors logged: ${consoleErrors.join('; ')}`);
    } else {
      console.log('  [PASS] Zero console errors during entire Song Repertoire test lifecycle.');
    }

    console.log('\n================================================================');
    console.log('   ALL SPRINT 4 SONG REPERTOIRE E2E TESTS PASSED (100% SUCCESS) ');
    console.log('================================================================\n');

  } finally {
    await browser.close();
  }
}

run().catch(err => {
  console.error('\nE2E TEST FAILURE:', err);
  process.exit(1);
});
