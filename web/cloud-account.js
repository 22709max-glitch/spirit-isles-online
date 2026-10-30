const SESSION_KEY='spirit-online-session-v1';
export function canonical(value){
 if(Array.isArray(value))return value.map(canonical);
 if(value&&typeof value==='object')return Object.fromEntries(Object.keys(value).filter(k=>k!=='saved_at').sort().map(k=>[k,canonical(value[k])]));
 return value;
}
export function sameSave(a,b){return JSON.stringify(canonical(a))===JSON.stringify(canonical(b));}
export function validSave(s){return s?.version===1&&s.profile&&Array.isArray(s.profile.party)&&s.profile.party.length>0&&s.world&&s.position;}
export function publicConfig(config){
 if(!config.supabaseUrl||!config.publishableKey)return null;
 const u=new URL(config.supabaseUrl);if(u.protocol!=='https:')throw Error('帳號服務需要HTTPS網址。');
 const key=config.publishableKey;
 if(key.startsWith('sb_secret_'))throw Error('請使用公開publishable key，不能使用秘密金鑰。');
 if(key.split('.').length===3){try{const payload=JSON.parse(atob(key.split('.')[1].replace(/-/g,'+').replace(/_/g,'/')));if(payload.role!=='anon')throw Error('請使用公開anon key，不能使用service_role。');}catch(e){throw Error('公開金鑰格式或權限不正確。');}}
 else if(!key.startsWith('sb_publishable_'))throw Error('請填Supabase公開publishable key。');
 return {...config,supabaseUrl:u.origin};
}
export class CloudAccount{
 constructor(config,{fetcher=fetch,storage=localStorage,now=()=>Date.now()}={}){this.config=publicConfig(config);this.fetcher=fetcher;this.storage=storage;this.now=now;this.session=null;this.revision=0;this.remote=null;}
 get enabled(){return !!this.config;}
 get user(){return this.session?.user||null;}
 get scope(){return this.user?'user-'+this.user.id:'guest';}
 get saveKey(){return 'spirit-isles-save-v1:'+this.scope;}
 get metaKey(){return 'spirit-online-sync:'+this.scope;}
 async request(path,{method='GET',body,auth=false}={}){
  if(!this.enabled)throw Error('帳號與雲端存檔尚未啟用。');
  if(auth)await this.refresh();
  const headers={apikey:this.config.publishableKey,'Content-Type':'application/json'};
  if(auth){if(!this.session)throw Error('請重新登入。');headers.Authorization='Bearer '+this.session.access_token;}
  const response=await this.fetcher(this.config.supabaseUrl+path,{method,headers,body:body===undefined?undefined:JSON.stringify(body)});
  const data=await response.json().catch(()=>({}));
  if(!response.ok){const e=Error(data.msg||data.message||data.error_description||'服務暫時無法使用，請稍後再試。');e.status=response.status;if(e.message.includes('SAVE_CONFLICT'))e.code='SAVE_CONFLICT';throw e;}
  return data;
 }
 storeSession(session){
  if(!session?.access_token||!session?.refresh_token||!session?.user?.id)throw Error('登入資料不完整。');
  this.session={...session,expires_at:session.expires_at||Math.floor(this.now()/1000)+(session.expires_in||3600)};
  this.storage.setItem(SESSION_KEY,JSON.stringify(this.session));
 }
 async resume(){
  if(!this.enabled)return false;
  try{const raw=JSON.parse(this.storage.getItem(SESSION_KEY)||'null');if(!raw)return false;this.session=raw;await this.refresh();const user=await this.request('/auth/v1/user',{auth:true});this.session.user=user;this.storage.setItem(SESSION_KEY,JSON.stringify(this.session));return true;}
  catch(e){if(e.status===400||e.status===401||e.status===403){this.session=null;this.storage.removeItem(SESSION_KEY);return false;}throw e;}
 }
 async refresh(){
  if(!this.session)return;
  if(this.session.expires_at*1000>this.now()+60000)return;
  if(!this.refreshing)this.refreshing=this.request('/auth/v1/token?grant_type=refresh_token',{method:'POST',body:{refresh_token:this.session.refresh_token}}).then(s=>this.storeSession(s)).finally(()=>this.refreshing=null);
  await this.refreshing;
 }
 async signup(email,password,redirect){
  if(password.length<8)throw Error('密碼至少需要8個字元。');
  const data=await this.request('/auth/v1/signup?redirect_to='+encodeURIComponent(redirect),{method:'POST',body:{email,password}});
  if(data.access_token)this.storeSession(data);
  return !!data.access_token;
 }
 async login(email,password){const data=await this.request('/auth/v1/token?grant_type=password',{method:'POST',body:{email,password}});this.storeSession(data);}
 async recover(email,redirect){await this.request('/auth/v1/recover?redirect_to='+encodeURIComponent(redirect),{method:'POST',body:{email}});}
 async setPassword(password){if(password.length<8)throw Error('密碼至少需要8個字元。');await this.request('/auth/v1/user',{method:'PUT',auth:true,body:{password}});}
 async acceptLink(hash){
  const p=new URLSearchParams(hash.replace(/^#/,''));if(!p.has('access_token'))return null;
  const provisional={access_token:p.get('access_token'),refresh_token:p.get('refresh_token'),expires_in:Number(p.get('expires_in')||3600),user:{id:''}};
  const response=await this.fetcher(this.config.supabaseUrl+'/auth/v1/user',{headers:{apikey:this.config.publishableKey,Authorization:'Bearer '+provisional.access_token}});if(!response.ok)throw Error('驗證連結已失效，請重新登入或申請重設密碼。');
  provisional.user=await response.json();this.storeSession(provisional);return p.get('type');
 }
 async read(){
  const rows=await this.request('/rest/v1/player_saves?select=save,revision,updated_at&user_id=eq.'+encodeURIComponent(this.user.id),{auth:true});
  if(rows.length>1)throw Error('雲端存檔資料不正確。');
  this.remote=rows[0]||null;this.revision=this.remote?.revision||0;return this.remote;
 }
 local(){try{const save=JSON.parse(this.storage.getItem(this.saveKey)||'null');return validSave(save)?save:null;}catch{return null;}}
 needsChoice(local,remote){return !!(local&&remote&&!sameSave(local,remote.save));}
 install(save){if(!validSave(save))throw Error('存檔格式不正確。');const copy={...save,saved_at:this.now()/1000};this.storage.setItem(this.saveKey,JSON.stringify(copy));return copy;}
 async upload(save){
  if(!validSave(save))throw Error('請先開始冒險，再儲存雲端進度。');
  const rows=await this.request('/rest/v1/rpc/save_player_game',{method:'POST',auth:true,body:{p_save:save,p_expected_revision:this.revision}});
  if(!rows[0]?.revision)throw Error('雲端尚未確認存檔成功。');
  this.revision=rows[0].revision;this.remote={save,revision:this.revision,updated_at:rows[0].updated_at};this.storage.setItem(this.metaKey,JSON.stringify({revision:this.revision}));return this.remote;
 }
 async logout(){
  let failure=null;try{await this.request('/auth/v1/logout',{method:'POST',auth:true});}catch(e){failure=e;}finally{this.session=null;this.storage.removeItem(SESSION_KEY);}
  return failure;
 }
}
