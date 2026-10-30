from pathlib import Path
from playwright.sync_api import sync_playwright
import json,os,urllib.parse,subprocess,time
r=Path(__file__).resolve().parents[1];url='https://22709max-glitch.github.io/spirit-isles-online/'
for attempt in range(60):
 result=subprocess.run(['curl','--silent','--show-error','--location','--max-time','15','-o','/tmp/spirit-pages-ready.html','-w','%{http_code}',url+'web/?check='+str(int(time.time()))],capture_output=True,text=True)
 if result.stdout=='200':break
 if attempt%6==0:print('WAITING_FOR_PAGES',result.stdout,flush=True)
 time.sleep(5)
else:raise RuntimeError('Public site not ready')
errors=[];checks=[]
with sync_playwright() as pw:
 launch={'executable_path':'/usr/bin/chromium','headless':True,'args':['--no-sandbox','--use-angle=swiftshader','--enable-unsafe-swiftshader','--disable-dev-shm-usage','--autoplay-policy=no-user-gesture-required']}
 proxy=urllib.parse.urlparse(os.environ.get('HTTPS_PROXY') or os.environ.get('https_proxy',''))
 if proxy.hostname:
  launch['proxy']={'server':f'{proxy.scheme}://{proxy.hostname}:{proxy.port or 80}'}
  if proxy.username:launch['proxy'].update(username=urllib.parse.unquote(proxy.username),password=urllib.parse.unquote(proxy.password or ''))
 if proxy.hostname:
  # Chromium has a separate trust store. Pin only the proxy leaf key already
  # authenticated by curl's normal system certificate validation for this URL.
  import re,hashlib,base64
  certs=subprocess.check_output(['curl','--fail','--silent','--show-error','--location','--max-time','25','-o','/dev/null','-w','%{certs}',url]).decode()
  cert=re.search(r'-----BEGIN CERTIFICATE-----.*?-----END CERTIFICATE-----',certs,re.S).group(0)
  key=subprocess.check_output(['openssl','x509','-pubkey','-noout'],input=cert.encode())
  der=subprocess.check_output(['openssl','pkey','-pubin','-outform','DER'],input=key)
  launch['args'].append('--ignore-certificate-errors-spki-list='+base64.b64encode(hashlib.sha256(der).digest()).decode())
 b=pw.chromium.launch(**launch);ctx=b.new_context(viewport={'width':390,'height':844},is_mobile=True,has_touch=True);p=ctx.new_page();p.on('pageerror',lambda e:errors.append(str(e)));p.on('console',lambda m:errors.append(m.text) if 'ERROR' in m.text else None)
 response=p.goto(url,wait_until='networkidle',timeout=60000);p.get_by_role('button',name='直接開始遊玩',exact=True).wait_for(timeout=20000);checks.append('public HTTPS page redirects to actual mobile game');assert p.get_by_role('button',name='登入／註冊',exact=True).is_disabled()
 p.get_by_role('button',name='直接開始遊玩',exact=True).tap();p.wait_for_function('window.spiritReady&&window.spiritMobileTree?.tree?.id',timeout=240000);p.get_by_role('button',name='選擇這位夥伴',exact=True).nth(1).tap();p.wait_for_timeout(800);p.evaluate('window.spiritAction(JSON.stringify({kind:"menu",name:"close"}))');p.wait_for_timeout(500);checks.append('real public PCK and WASM load and character selection succeeds')
 p.get_by_role('button',name='存檔',exact=True).tap();p.wait_for_timeout(1000);raw=p.evaluate('localStorage.getItem("spirit-isles-save-v1:guest")');assert json.loads(raw)['profile']['party'];checks.append('public origin visitor save persists under isolated key');p.screenshot(path=str(r/'validation/live-phone.png'))
 p.reload(wait_until='networkidle',timeout=60000);p.get_by_role('button',name='直接開始遊玩',exact=True).wait_for(timeout=20000);assert p.evaluate('localStorage.getItem("spirit-isles-save-v1:guest")')==raw;checks.append('browser refresh retains player progress')
 other=b.new_context(viewport={'width':390,'height':844},is_mobile=True,has_touch=True);q=other.new_page();q.goto(url,wait_until='networkidle',timeout=60000);assert q.evaluate('localStorage.getItem("spirit-isles-save-v1:guest")') is None;checks.append('another browser using same public URL cannot see first player save');other.close()
 assert not errors,errors
 (r/'validation/live-browser.json').write_text(json.dumps({'url':url,'checks':checks,'errors':errors,'actual_phone_hardware_tested':False,'accounts_enabled':False,'environment_proxy_certificate_pinned_for_browser':True,'public_https_verified_with_system_trust':True},ensure_ascii=False,indent=2));print('LIVE_BROWSER_PASS',checks,flush=True);b.close()
