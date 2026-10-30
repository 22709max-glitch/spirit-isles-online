from pathlib import Path
from playwright.sync_api import sync_playwright
import subprocess,json
r=Path(__file__).resolve().parents[1];checks=[]
legacy_html=subprocess.check_output(['git','show','2e9b612:web/index.html'],cwd=r).decode();old_pack=Path('/workspace/spirit-isles-game/build/v093/mobile/index.pck')
with sync_playwright() as pw:
 b=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--use-angle=swiftshader','--enable-unsafe-swiftshader','--disable-dev-shm-usage','--autoplay-policy=no-user-gesture-required']);p=b.new_page(viewport={'width':390,'height':844},is_mobile=True,has_touch=True)
 def old_html(route):route.fulfill(status=200,content_type='text/html',body=legacy_html)
 def old_pck(route):route.fulfill(status=200,content_type='application/octet-stream',path=str(old_pack))
 p.route('http://127.0.0.1:8770/',old_html);p.route('**/index.pck',old_pck)
 p.goto('http://127.0.0.1:8770/',wait_until='networkidle');p.get_by_role('button',name='直接開始遊玩',exact=True).tap();p.wait_for_function('window.spiritReady&&window.spiritMobileTree?.tree?.id',timeout=120000);p.get_by_role('button',name='選擇這位夥伴',exact=True).nth(1).tap();p.wait_for_timeout(500)
 for c in [{'kind':'menu','name':'close'},{'kind':'tester_unlock','password':'SPIRIT-TEST-07'},{'kind':'tester_coins','value':1234},{'kind':'save'}]:p.evaluate('(c)=>window.spiritAction(JSON.stringify(c))',c);p.wait_for_timeout(250)
 p.wait_for_timeout(1500);before=json.loads(p.evaluate('localStorage.getItem("spirit-isles-save-v1:guest")'));assert before['profile']['coins']==1234;checks.append('old published game stores a real visitor profile')
 p.unroute('http://127.0.0.1:8770/',old_html);p.unroute('**/index.pck',old_pck);p.reload(wait_until='networkidle');p.get_by_role('button',name='直接開始遊玩',exact=True).tap();p.wait_for_function('window.spiritReady&&window.spiritMobileTree?.tree?.id',timeout=120000);p.get_by_role('button',name='繼續上次冒險',exact=True).tap();p.wait_for_timeout(1000);after=p.evaluate('window.spiritState.room.players[window.spiritState.local_id]');assert after['coins']==1234 and after['party'][0]['uid']==before['profile']['party'][0]['uid'];checks.append('new versioned game pack resumes original coins and spirit without clearing site data')
 (r/'validation/mobile-save-upgrade.json').write_text(json.dumps({'checks':checks},ensure_ascii=False,indent=2));print('MOBILE_UPGRADE_PASS',checks,flush=True);b.close()
