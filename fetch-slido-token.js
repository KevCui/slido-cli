const puppeteer = require('puppeteer');

(async () => {
  const url = process.argv[2]
  const isheadless = true;
  const chrome = '/usr/bin/chromium';
  const privacybtn='#app > div.privacy-manager.privacy-manager__banner.privacy-manager--no-consent-action > button > svg';
  const questionlist='#app > div:nth-child(2) > div > div > div > div > div.app__content > div > div > sda-live > div > div > sda-questions > sda-question-list'

  const browser = await puppeteer.launch({executablePath: chrome, headless: isheadless});
  const page = await browser.newPage();
  await page.goto(url, {timeout: 10000, waitUntil: 'domcontentloaded'});
  await page.waitFor(questionlist);
  await page.click(privacybtn);

  let cookie = await page.cookies();
  let token = cookie.filter(c => c['name'] === 'Slido.EventAuthTokens');
  console.log(token[0]['value'].replace(/\"/g, ''));

  await browser.close();
})();
