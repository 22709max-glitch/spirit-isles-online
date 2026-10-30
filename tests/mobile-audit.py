from pathlib import Path
from playwright.sync_api import sync_playwright
import json,os
r=Path(__file__).resolve().parents[1];out=r/'validation/mobile-audit-current';out.mkdir(exist_ok=True)
with sync_playwright() as pw:
 b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--use-angle=swiftshader','--enable-unsafe-swiftshader','--disable-dev-shm-usage','--autoplay-policy=no-user-gesture-required']);p=b.new_page(viewport={'width':390,'height':844},is_mobile=True,has_touch=True);errors=[];p.on('pageerror',lambda e:errors.append(str(e)))
 p.goto('http://127.0.0.1:8770/',wait_until='networkidle');p.get_by_role('button',name='直接開始遊玩',exact=True).tap();p.wait_for_function('window.spiritReady&&window.spiritMobileTree?.tree?.id',timeout=120000);p.wait_for_timeout(600);p.screenshot(path=str(out/'starter.png'));p.get_by_role('button',name='選擇這位夥伴',exact=True).nth(1).tap();p.wait_for_timeout(500)
 def cmd(c):p.evaluate('(c)=>window.spiritAction(JSON.stringify(c))',c);p.wait_for_timeout(650)
 cmd({'kind':'menu','name':'close'});p.screenshot(path=str(out/'explore.png'));report=[]
 for name in ['party','inventory','codex','rewards','world_map','more','training','workshop','lottery']:
  cmd({'kind':'menu','name':name});p.screenshot(path=str(out/(name+'.png')))
  metrics=p.locator('#menu').evaluate('''e=>({width:e.clientWidth,scrollWidth:e.scrollWidth,scrollHeight:e.scrollHeight,height:e.clientHeight,buttons:[...e.querySelectorAll('button')].filter(b=>{const r=b.getBoundingClientRect();return r.width<42||r.height<42||r.right>innerWidth+1}).map(b=>({text:b.innerText,rect:b.getBoundingClientRect().toJSON()})).slice(0,8)})''');report.append({'page':name,**metrics})
 (out/'audit.json').write_text(json.dumps({'pages':report,'errors':errors},ensure_ascii=False,indent=2));print(json.dumps({'pages':report,'errors':errors},ensure_ascii=False),flush=True);b.close()
