const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

async function exploreEPGInterface() {
  const browser = await chromium.launch({ headless: false });
  const context = await browser.newContext({
    viewport: { width: 1920, height: 1080 }
  });
  const page = await context.newPage();

  const screenshotsDir = path.join(__dirname, 'epg_screenshots');
  if (!fs.existsSync(screenshotsDir)) {
    fs.mkdirSync(screenshotsDir);
  }

  try {
    console.log('Step 1: Navigating to web UI home page...');
    await page.goto('http://localhost:32400/ui/');
    await page.waitForLoadState('networkidle');
    await page.waitForTimeout(2000); // Wait for React to render
    await page.screenshot({ path: path.join(screenshotsDir, '01_login_page.png'), fullPage: true });

    // Login
    console.log('Logging in...');
    await page.fill('#username', 'admin');
    await page.fill('#password', 'admin123');
    await page.click('button:has-text("Sign in")');
    await page.waitForTimeout(2000);
    await page.screenshot({ path: path.join(screenshotsDir, '02_after_login.png'), fullPage: true });

    // Get navigation elements
    const navText = await page.evaluate(() => {
      const navElements = Array.from(document.querySelectorAll('nav a, nav button, header a, header button, [role="navigation"] a, [role="navigation"] button, .sidebar a, .sidebar button'));
      return navElements.map(el => ({
        text: el.textContent.trim(),
        href: el.getAttribute('href'),
        class: el.className
      }));
    });
    console.log('Navigation elements found:', JSON.stringify(navText, null, 2));

    console.log('\nStep 2: Looking for Live TV management...');
    // Try to find Live TV link
    const liveTVSelectors = [
      'a:has-text("Live TV")',
      'a:has-text("EPG")',
      'a:has-text("TV Guide")',
      'button:has-text("Live TV")',
      'nav a[href*="livetv"]',
      'nav a[href*="epg"]'
    ];

    let liveTVFound = false;
    for (const selector of liveTVSelectors) {
      try {
        const element = await page.locator(selector).first();
        if (await element.isVisible({ timeout: 1000 })) {
          console.log(`Found Live TV link with selector: ${selector}`);
          await element.click();
          liveTVFound = true;
          break;
        }
      } catch (e) {
        // Continue to next selector
      }
    }

    if (!liveTVFound) {
      console.log('Live TV link not found in navigation, checking page content...');
      const pageText = await page.textContent('body');
      console.log('Page contains "Live TV":', pageText.includes('Live TV'));
      console.log('Page contains "EPG":', pageText.includes('EPG'));
    }

    await page.waitForTimeout(1000);
    await page.screenshot({ path: path.join(screenshotsDir, '03_after_livetv_click.png'), fullPage: true });

    console.log('\nStep 3: Looking for EPG sources...');
    // Look for settings, configuration, or admin links
    const settingsSelectors = [
      'a:has-text("Settings")',
      'a:has-text("Configuration")',
      'a:has-text("Admin")',
      'a:has-text("EPG Sources")',
      'button:has-text("Settings")',
      '[aria-label*="Settings"]',
      '[aria-label*="Menu"]'
    ];

    let settingsFound = false;
    for (const selector of settingsSelectors) {
      try {
        const element = await page.locator(selector).first();
        if (await element.isVisible({ timeout: 1000 })) {
          console.log(`Found settings with selector: ${selector}`);
          await element.click();
          settingsFound = true;
          await page.waitForTimeout(500);
          break;
        }
      } catch (e) {
        // Continue
      }
    }

    await page.screenshot({ path: path.join(screenshotsDir, '04_settings_or_epg_sources.png'), fullPage: true });

    console.log('\nStep 4: Looking for EPG Editor/Mapper...');
    const epgEditorSelectors = [
      'a:has-text("EPG Editor")',
      'a:has-text("EPG Mapper")',
      'a:has-text("Channel Mapping")',
      'a:has-text("Simple Mode")',
      'button:has-text("EPG Editor")',
      'button:has-text("EPG Mapper")',
      '[href*="epg"]',
      '[href*="mapper"]',
      '[href*="editor"]'
    ];

    let epgEditorFound = false;
    for (const selector of epgEditorSelectors) {
      try {
        const element = await page.locator(selector).first();
        if (await element.isVisible({ timeout: 1000 })) {
          console.log(`Found EPG Editor with selector: ${selector}`);
          await element.click();
          epgEditorFound = true;
          await page.waitForTimeout(1000);
          break;
        }
      } catch (e) {
        // Continue
      }
    }

    await page.screenshot({ path: path.join(screenshotsDir, '05_epg_editor_page.png'), fullPage: true });

    console.log('\nStep 5: Analyzing EPG Editor interface...');

    // Get all visible text and structure
    const pageAnalysis = await page.evaluate(() => {
      const analysis = {
        headings: [],
        buttons: [],
        inputs: [],
        selects: [],
        tables: [],
        lists: []
      };

      // Get headings
      document.querySelectorAll('h1, h2, h3, h4, h5, h6').forEach(h => {
        if (h.offsetParent !== null) { // visible check
          analysis.headings.push({
            tag: h.tagName,
            text: h.textContent.trim()
          });
        }
      });

      // Get buttons
      document.querySelectorAll('button').forEach(btn => {
        if (btn.offsetParent !== null) {
          analysis.buttons.push({
            text: btn.textContent.trim(),
            class: btn.className,
            disabled: btn.disabled
          });
        }
      });

      // Get inputs
      document.querySelectorAll('input').forEach(input => {
        if (input.offsetParent !== null) {
          analysis.inputs.push({
            type: input.type,
            placeholder: input.placeholder,
            name: input.name,
            id: input.id
          });
        }
      });

      // Get selects
      document.querySelectorAll('select').forEach(select => {
        if (select.offsetParent !== null) {
          analysis.selects.push({
            name: select.name,
            id: select.id,
            options: Array.from(select.options).map(o => o.text)
          });
        }
      });

      // Get tables
      document.querySelectorAll('table').forEach(table => {
        if (table.offsetParent !== null) {
          const headers = Array.from(table.querySelectorAll('th')).map(th => th.textContent.trim());
          const rowCount = table.querySelectorAll('tbody tr').length;
          analysis.tables.push({
            headers,
            rowCount
          });
        }
      });

      // Get lists
      document.querySelectorAll('ul, ol').forEach(list => {
        if (list.offsetParent !== null && list.children.length > 0) {
          const items = Array.from(list.children).slice(0, 5).map(li => li.textContent.trim().substring(0, 100));
          analysis.lists.push({
            type: list.tagName,
            itemCount: list.children.length,
            sampleItems: items
          });
        }
      });

      return analysis;
    });

    console.log('\nPage Analysis:', JSON.stringify(pageAnalysis, null, 2));

    // Take a screenshot of any dropdown or select elements
    const selects = await page.locator('select').all();
    for (let i = 0; i < Math.min(selects.length, 3); i++) {
      try {
        await selects[i].scrollIntoViewIfNeeded();
        await page.screenshot({
          path: path.join(screenshotsDir, `06_select_element_${i}.png`),
          fullPage: false
        });
      } catch (e) {
        console.log(`Could not screenshot select ${i}:`, e.message);
      }
    }

    // Look for mapping interface elements
    console.log('\nLooking for mapping interface elements...');
    const mappingElements = await page.evaluate(() => {
      const elements = {
        m3uChannelList: null,
        epgChannelList: null,
        mapButtons: [],
        unmapButtons: [],
        bulkActions: []
      };

      // Look for channel lists
      const lists = document.querySelectorAll('ul, ol, [role="listbox"], [role="list"]');
      lists.forEach((list, idx) => {
        const text = list.textContent.toLowerCase();
        if (text.includes('m3u') || text.includes('channel')) {
          elements.m3uChannelList = {
            index: idx,
            childCount: list.children.length,
            sample: Array.from(list.children).slice(0, 3).map(c => c.textContent.trim())
          };
        }
        if (text.includes('epg') || text.includes('guide')) {
          elements.epgChannelList = {
            index: idx,
            childCount: list.children.length,
            sample: Array.from(list.children).slice(0, 3).map(c => c.textContent.trim())
          };
        }
      });

      // Look for map/unmap buttons
      document.querySelectorAll('button').forEach(btn => {
        const text = btn.textContent.toLowerCase();
        if (text.includes('map') && !text.includes('unmap')) {
          elements.mapButtons.push({
            text: btn.textContent.trim(),
            class: btn.className
          });
        }
        if (text.includes('unmap')) {
          elements.unmapButtons.push({
            text: btn.textContent.trim(),
            class: btn.className
          });
        }
        if (text.includes('bulk') || text.includes('all')) {
          elements.bulkActions.push({
            text: btn.textContent.trim(),
            class: btn.className
          });
        }
      });

      return elements;
    });

    console.log('\nMapping Elements Found:', JSON.stringify(mappingElements, null, 2));

    // Take final screenshots
    await page.screenshot({ path: path.join(screenshotsDir, '07_final_overview.png'), fullPage: true });

    console.log('\nTaking focused screenshots of key areas...');

    // Try to screenshot the main content area
    const mainSelectors = ['main', '[role="main"]', '.content', '#content', '.container'];
    for (const selector of mainSelectors) {
      try {
        const element = await page.locator(selector).first();
        if (await element.isVisible({ timeout: 500 })) {
          await element.screenshot({ path: path.join(screenshotsDir, '08_main_content.png') });
          break;
        }
      } catch (e) {
        // Continue
      }
    }

    console.log('\nExploration complete! Screenshots saved to:', screenshotsDir);

  } catch (error) {
    console.error('Error during exploration:', error);
    await page.screenshot({ path: path.join(screenshotsDir, 'error_state.png'), fullPage: true });
  } finally {
    await browser.close();
  }
}

exploreEPGInterface().catch(console.error);
