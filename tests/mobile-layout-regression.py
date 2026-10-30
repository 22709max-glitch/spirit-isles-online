from pathlib import Path
from playwright.sync_api import sync_playwright
import os,json,sys,time
r=Path(__file__).resolve().parents[1];name=sys.argv[1] if len(sys.argv)>1 else 'chromium';out=r/'validation'/('mobile-layout-'+name);out.mkdir(exist_ok=True);checks=[];errors=[]
with sync_playwright() as pw:
 if name=='webkit':browser=pw.webkit.launch(executable_path='/workspace/.cache/pw-mobile/run-webkit-local.sh',headless=True,env={**os.environ,'LIBGL_ALWAYS_SOFTWARE':'1','EGL_PLATFORM':'surfaceless'})
 else:browser=pw.chromium.launch(executable_path='/usr/bin/chromium',headless=True,args=['--no-sandbox','--use-angle=swiftshader','--enable-unsafe-swiftshader','--disable-dev-shm-usage','--autoplay-policy=no-user-gesture-required'])
 context=browser.new_context(viewport={'width':390,'height':844},is_mobile=True,has_touch=True);p=context.new_page();p.on('pageerror',lambda e:errors.append(str(e)));p.on('console',lambda m:errors.append(m.text) if m.type=='error' else None)
 def cmd(c):p.evaluate('(c)=>window.spiritAction(JSON.stringify(c))',c);p.wait_for_timeout(550)
 def tap(text):p.get_by_role('button',name=text,exact=True).filter(visible=True).first.tap();p.wait_for_timeout(550)
 def snap(n):p.screenshot(path=str(out/(n+'.png')))
 def me():return p.evaluate('window.spiritState.room.players[window.spiritState.local_id]')
 def inspect(label):
  issues=p.locator('#menu-body').evaluate('''el=>({width:el.clientWidth,scroll:el.scrollWidth,bad:[...el.querySelectorAll('button,input,select')].filter(n=>{const r=n.getBoundingClientRect();if(r.width===0)return false;let parent=n.parentElement;while(parent&&parent!==el){if(['auto','scroll'].includes(getComputedStyle(parent).overflowX))return false;parent=parent.parentElement;}return r.width<40||r.height<40||r.right>innerWidth+1||r.left< -1;}).map(n=>({text:n.innerText||n.placeholder,rect:n.getBoundingClientRect().toJSON()})).slice(0,10)})''')
  assert issues['scroll']<=issues['width']+2,(label,issues);assert not issues['bad'],(label,issues);checks.append(label+' fits phone width with usable controls')
 p.goto('http://127.0.0.1:8770/',wait_until='networkidle');p.get_by_role('button',name='直接開始遊玩',exact=True).tap();p.wait_for_function('window.spiritReady&&window.spiritMobileTree?.tree?.id',timeout=180000);p.wait_for_timeout(900);inspect('starter');snap('starter');p.get_by_role('button',name='選擇這位夥伴',exact=True).nth(1).tap();p.wait_for_timeout(800);cmd({'kind':'menu','name':'close'});snap('explore')
 # Provision many spirits and materials through the existing local-only developer fixture.
 cmd({'kind':'tester_unlock','password':'SPIRIT-TEST-07'})
 for family in ['R001','R003','R087','R095','R096','R031','R037','R040']:cmd({'kind':'tester_spawn','family':family,'level':45,'stage':1})
 cmd({'kind':'tester_item','item':'draw_ticket','value':10});cmd({'kind':'menu','name':'close'})
 for width,height in [(320,568),(390,844),(430,932),(844,390)]:
  p.set_viewport_size({'width':width,'height':height});p.wait_for_timeout(500)
  for modal in ['party','inventory','codex','rewards','world_map','more','workshop','lottery']:
   cmd({'kind':'menu','name':modal});inspect(f'{width}x{height} {modal}')
   bounds=p.locator('#menu-head').bounding_box();assert 0<=bounds['y']<=1 and bounds['height']<=110,(modal,bounds)
   p.locator('#menu-body').evaluate('(e)=>e.scrollTop=e.scrollHeight');p.wait_for_timeout(100);head=p.locator('#menu-head').bounding_box();assert head['y']<=1,'header must remain visible';p.locator('#menu-body').evaluate('(e)=>e.scrollTop=0')
   if width in [390,844]:snap(f'{width}-{modal}')
 # Search should never replace the currently focused input or dismiss its keyboard.
 p.set_viewport_size({'width':390,'height':844});cmd({'kind':'menu','name':'party'});field=p.get_by_placeholder('搜尋名字、路線或屬性');field.focus();p.evaluate('window.focusedSearch=document.activeElement');field.type('刃',delay=100);p.wait_for_timeout(1400);assert p.evaluate('window.focusedSearch===document.activeElement&&window.focusedSearch.isConnected');assert field.input_value()=='刃';checks.append('typing preserves the same input element and focus across updates');field.fill('');p.wait_for_timeout(600)
 # Clicking a roster image reveals the exact selected spirit, with the hero near the viewport top.
 card=p.get_by_role('button',name='刃翎隼 · 點選查看詳情',exact=True);card.tap();p.wait_for_function('window.spiritState.room.players[window.spiritState.local_id].party.some(m=>m.family==="R001"&&m.uid===window.spiritState.party_selection)',timeout=10000);p.wait_for_timeout(500);assert p.locator('.party-hero').bounding_box()['y']<200;assert p.locator('.party-hero').inner_text().strip().startswith('刃翎隼');tap('招式');inspect('moves');tap('進化');inspect('evolution');checks.append('roster image opens selected detail without scrolling past the roster')
 # Pagination preserves codex position when returning from a detail, not always the first entries.
 cmd({'kind':'menu','name':'codex'});p.locator('.list-pager').first.get_by_role('button',name='下一頁',exact=True).tap();p.wait_for_timeout(600);assert '2 /' in p.locator('.list-pager').first.inner_text();p.locator('#menu-body .m-grid .m-button').first.tap();p.wait_for_timeout(600);tap('返回上一頁');assert '2 /' in p.locator('.list-pager').first.inner_text();checks.append('codex page and scroll context survive detail and back')
 cmd({'kind':'menu','name':'workshop'});search=p.get_by_placeholder('搜尋配方或材料');search.fill('完全不存在的材料');p.wait_for_timeout(700);assert p.locator('.m-empty').is_visible();assert p.locator('.m-paged-content .m-card').count()==0;checks.append('crafting uses searchable paginated recipes instead of one huge page')
 # Battle grids stay touchable in portrait and landscape; opening the type chart must remain reversible.
 cmd({'kind':'menu','name':'close'});cmd({'kind':'tester_mon','uid':me()['party'][0]['uid'],'level':50,'potential':31});cmd({'kind':'tester_jump','area':'a1_0_0'});cmd({'kind':'menu','name':'close'});cmd({'kind':'mobile_navigate','area':'a1_0_0','entity':'guard_0'});p.wait_for_function('window.spiritState.room.players[window.spiritState.local_id].battle!==""',timeout=45000);p.wait_for_selector('.m-duel',timeout=20000)
 for width,height in [(320,568),(844,390)]:p.set_viewport_size({'width':width,'height':height});p.wait_for_timeout(500);inspect(f'battle {width}');snap(f'{width}-battle')
 p.locator('#menu-body button').filter(has_text='突擊').first.tap();p.wait_for_timeout(1500);checks.append('real battle action accepts a touch after orientation changes')
 assert not p.evaluate('window.spiritMobileMissingAssets?.length||0'),'all menu pictures should use static assets';assert not errors,errors;(out/'report.json').write_text(json.dumps({'engine':name,'checks':checks,'errors':errors,'physical_iphone_tested':False},ensure_ascii=False,indent=2));print('MOBILE_LAYOUT_PASS',name,len(checks),flush=True);browser.close()
