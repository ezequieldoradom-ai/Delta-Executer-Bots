import {createRequire} from 'node:module'; const require = createRequire(import.meta.url); const {chromium} = require('playwright');
import fs from 'node:fs';
const [,, sceneFile, outDir] = process.argv;
const data = fs.readFileSync(sceneFile,'utf8').split('\n').find(l=>l.includes(';'));
const views = JSON.parse(fs.readFileSync(process.argv[4],'utf8'));
const browser = await chromium.launch({args:['--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader']});
const page = await browser.newPage({viewport:{width:1600,height:900}});
await page.goto('http://127.0.0.1:8765/view.html');
await page.waitForFunction(()=>window.ready);
await page.evaluate(d=>window.build(d), data);
for (const v of views) {
  await page.evaluate(a=>window.shot(...a), v.cam);
  await page.screenshot({path:`${outDir}/${v.name}.png`});
  console.log('ok', v.name);
}
await browser.close();
