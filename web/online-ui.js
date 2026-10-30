import {CloudAccount,sameSave,validSave} from './cloud-account.js';
const byId=id=>document.getElementById(id),send=c=>window.spiritAction?.(JSON.stringify(c));
const escapeText=value=>String(value??'');
let cloud,loaded=false,syncing=false,conflict=false,bootSave=null;
const status=message=>{byId('cloud-status').textContent=message;};
const note=message=>byId('account-note').textContent=message;
const current=()=>{const s=window.spiritState;return s?.room?.players[s.local_id];};
const sleep=ms=>new Promise(r=>setTimeout(r,ms));
function summarize(save){if(!save)return '尚未開始冒險';return `精靈 ${save.profile.party.length} 隻 · 圖鑑 ${save.profile.dex?.length||0} 條 · 金幣 ${save.profile.coins||0}`;}
function choice(title,entries){
 const box=byId('save-choice'),list=byId('save-choices');byId('save-choice-title').textContent=title;list.replaceChildren();box.hidden=false;
 return new Promise(resolve=>entries.forEach(([label,value])=>{const b=document.createElement('button');b.textContent=label;b.onclick=()=>{box.hidden=true;resolve(value);};list.append(b);}));
}
async function prepare(){
 if(!cloud.user){window.SPIRIT_SAVE_SCOPE='guest';return;}
 const remote=await cloud.read(),local=cloud.local();let selected=remote?.save||local;
 if(cloud.needsChoice(local,remote))selected=await choice('選擇這次要繼續的進度',[[`雲端：${summarize(remote.save)}`,remote.save],[`這台裝置：${summarize(local)}`,local]]);
 if(!selected){
  let guest=null;try{guest=JSON.parse(localStorage.getItem('spirit-isles-save-v1:guest')||'null');}catch{}
  if(validSave(guest))selected=await choice('這個帳號尚無進度',[[`接續本機訪客進度：${summarize(guest)}`,guest],['從頭開始',null]]);
 }
 window.SPIRIT_SAVE_SCOPE=cloud.scope;if(selected){bootSave=cloud.install(selected);}status('已登入 · '+cloud.user.email);
}
async function capture(){
 const p=current();if(!p?.ready||p.battle)throw Error('請先開始冒險並結束目前戰鬥。');
 window.spiritMobileSave=null;send({kind:'mobile_export'});
 for(let i=0;i<50&&!window.spiritMobileSave;i++)await sleep(100);
 if(!window.spiritMobileSave)throw Error('目前無法儲存，請稍後再試。');
 const save=JSON.parse(window.spiritMobileSave);if(!validSave(save))throw Error('存檔資料不完整。');return save;
}
async function sync(manual=false){
 if(!cloud?.user||!loaded||syncing||conflict)return;
 const p=current();if(!p?.ready||p.battle)return;
 syncing=true;
 try{const save=await capture();if(!cloud.remote||!sameSave(save,cloud.remote.save)){await cloud.upload(save);}status('雲端已儲存 · '+new Date().toLocaleTimeString());}
 catch(e){if(e.code==='SAVE_CONFLICT'){conflict=true;status('其他裝置已更新進度，請開啟帳號頁選擇存檔。');}else status('目前保存在這台裝置，雲端尚未同步。'+(manual?e.message:''));}
 finally{syncing=false;}
}
function renderAccount(){
 byId('account-title').textContent=cloud?.user?'我的帳號':'登入／註冊';
 byId('auth-fields').hidden=!!cloud?.user;byId('account-actions').hidden=!cloud?.user;
 byId('account-email').textContent=cloud?.user?.email||'';
 byId('account-open').disabled=!cloud?.enabled;byId('account-toolbar').disabled=!cloud?.enabled;
 if(!cloud?.enabled)note('帳號與雲端存檔尚未啟用；現在可以先以訪客遊玩，每台裝置各自存檔。');
}
async function authenticate(mode){
 if(window.spiritReady&&current()?.battle){note('請先結束戰鬥，再切換帳號。');return;}
 const email=byId('auth-email').value.trim(),password=byId('auth-password').value;
 if(!email){note('請填寫Email。');return;}
 byId('login').disabled=true;byId('signup').disabled=true;
 try{
  if(mode==='signup'){const signed=await cloud.signup(email,password,location.origin+location.pathname);if(!signed){note('請到Email收件匣完成驗證，再回來登入。');return;}}
  else await cloud.login(email,password);
  byId('auth-password').value='';renderAccount();note('登入成功。');
  if(window.spiritReady){location.reload();return;}
  byId('account').hidden=true;byId('play').textContent='登入並開始遊玩';
 }catch(e){note(e.status===400?'帳號或密碼不正確，或Email尚未完成驗證。':e.message);}
 finally{byId('login').disabled=false;byId('signup').disabled=false;}
}
byId('account-open').onclick=()=>{renderAccount();note('');byId('account').hidden=false;};
byId('account-close').onclick=()=>byId('account').hidden=true;
byId('login').onclick=()=>authenticate('login');byId('signup').onclick=()=>authenticate('signup');
byId('recover').onclick=async()=>{try{const email=byId('auth-email').value.trim();if(!email)throw Error('請先填Email。');await cloud.recover(email,location.origin+location.pathname);note('如果Email已註冊，會收到重設密碼連結。');}catch(e){note(e.message);}};
byId('set-password').onclick=async()=>{try{await cloud.setPassword(byId('new-password').value);byId('new-password').value='';byId('password-recovery').hidden=true;note('密碼已更新。');}catch(e){note(e.message);}};
byId('cloud-save').onclick=async()=>{await sync(true);note(byId('cloud-status').textContent);};
byId('resolve-save').onclick=async()=>{
 if(!loaded)return;
 try{
  const local=await capture(),remote=await cloud.read();
  const selected=await choice('核對兩份進度後選擇',[[`保留雲端並下載：${summarize(remote?.save)}`,'cloud'],[`保留本機並上傳：${summarize(local)}`,'local'],['取消',null]]);
  if(!selected)return;
  if(selected==='cloud'){
   if(!remote)throw Error('雲端還沒有存檔。');
   send({kind:'mobile_import',value:JSON.stringify(cloud.install(remote.save))});conflict=false;status('已下載雲端進度。');
  }else{await cloud.upload(local);conflict=false;status('雲端已更新為這台裝置的進度。');}
  note(byId('cloud-status').textContent);
 }catch(e){note(e.code==='SAVE_CONFLICT'?'另一台裝置又更新了，請重新核對。':e.message);}
};
byId('logout').onclick=async()=>{
 if(current()?.battle){note('請先結束戰鬥，再登出。');return;}
 if(loaded)await sync(true);
 await cloud.logout();location.reload();
};
async function initialize(){
 try{
  const response=await fetch('online-config.json',{cache:'no-store'});cloud=new CloudAccount(await response.json());
  if(cloud.enabled){
   let link;try{link=await cloud.acceptLink(location.hash);}finally{if(location.hash.includes('access_token'))history.replaceState(null,'',location.pathname+location.search);}
   if(!link)await cloud.resume();
   if(link==='recovery'){byId('password-recovery').hidden=false;byId('account').hidden=false;}
  }
  renderAccount();byId('play').disabled=false;
  byId('play').textContent=cloud.user?'登入並開始遊玩':'直接開始遊玩';
  status(cloud.user?'已登入 · '+cloud.user.email:'訪客模式 · 存檔只保存在目前瀏覽器');
  const boot=window.startMobileEngine;
  window.startMobileEngine=async onProgress=>{
   await prepare();await boot(onProgress);
   for(let i=0;i<300&&!window.spiritReady;i++)await sleep(100);
   if(!window.spiritReady)throw Error('遊戲載入逾時，請重新整理。');
   if(bootSave)send({kind:'mobile_import',value:JSON.stringify(bootSave)});
   loaded=true;
  };
  byId('save').addEventListener('click',()=>setTimeout(()=>sync(true),200));setInterval(()=>sync(),45000);
 }catch(e){status(e.message);byId('play').disabled=true;byId('load-note').textContent='帳號服務設定或連線有問題：'+e.message+'。請稍後重新整理。';}
}
initialize();
