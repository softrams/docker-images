const { chromium } = require('playwright');

async function main() {
  const workspace = process.env.DEV_WORKSPACE;
  const username = process.env.DEV_LOGIN_USERNAME;
  const password = process.env.DEV_LOGIN_PASSWORD;
  const authFile = '/home/opencode/.local/share/playwright/auth.json';
  const baseUrl = `https://4i-${workspace}.dev.4innovation.cms.gov`;

  if (!workspace) {
    throw new Error('DEV_WORKSPACE is required for Playwright dev login');
  }

  if (!username || !password) {
    throw new Error('DEV_LOGIN_USERNAME and DEV_LOGIN_PASSWORD are required for Playwright dev login');
  }

  const browser = await chromium.launch({
    executablePath: '/usr/lib/chromium/chromium',
    headless: true,
  });

  try {
    const context = await browser.newContext();
    const page = await context.newPage();

    await page.goto(`${baseUrl}/auth/login`, { waitUntil: 'domcontentloaded' });

    const loginButton = page.getByRole('button', { name: 'Login' });
    if (await loginButton.isVisible().catch(() => false)) {
      await loginButton.click();
    }

    await page.getByRole('textbox', { name: 'Username' }).fill(username);
    await page.getByRole('textbox', { name: 'Password' }).fill(password);

    const acceptCheckbox = page.locator('#accept');
    if (await acceptCheckbox.count()) {
      await acceptCheckbox.check({ force: true }).catch(async () => {
        await page.locator('label[for="accept"]').click({ force: true });
      });
    }

    await page.locator("input[type='submit']").click();
    await page.waitForLoadState('networkidle', { timeout: 30000 }).catch(() => {});

    if (page.url().includes('/secure/setup/mfa')) {
      const skipButton = page.locator('button.skipStep');
      await skipButton.waitFor({ state: 'visible', timeout: 10000 });
      await skipButton.click();
    }

    await page.waitForURL(/aco-dashboard/i, { timeout: 60000 });
    await context.storageState({ path: authFile });
  } finally {
    await browser.close();
  }
}

main().catch((error) => {
  console.error(error instanceof Error ? error.message : String(error));
  process.exit(1);
});
