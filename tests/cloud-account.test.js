import {test} from 'node:test';import assert from 'node:assert/strict';import {CloudAccount,sameSave,publicConfig} from '../web/cloud-account.js';
const config={supabaseUrl:'https://example.supabase.co',publishableKey:'sb_publishable_test'};
const storage=()=>{const m=new Map();return {getItem:k=>m.get(k)||null,setItem:(k,v)=>m.set(k,v),removeItem:k=>m.delete(k)};};
const save=(coins=10)=>({version:1,saved_at:1,profile:{party:[{family:'R002'}],coins},world:{flags:{}},position:{area:'village',x:15,y:13}});
function service(){const rows=new Map(),calls=[];return {rows,calls,fetcher:async(url,opt={})=>{
 const path=new URL(url),body=opt.body?JSON.parse(opt.body):{},id=opt.headers?.Authorization?.split(' ')[1],ok=(data,status=200)=>new Response(JSON.stringify(data),{status});calls.push({url,opt});
 if(path.pathname==='/auth/v1/token'){const user=body.email==='b@example.com'?'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb':'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';return ok({access_token:user,refresh_token:user,expires_in:3600,user:{id:user,email:body.email}});}
 if(path.pathname==='/auth/v1/signup')return ok({user:{id:'pending'}});
 if(path.pathname==='/auth/v1/user')return id?ok({id,email:'a@example.com'}):ok({},401);
 if(path.pathname==='/auth/v1/logout')return ok({});
 if(!id)return ok({message:'unauthorized'},401);
 if(path.pathname==='/rest/v1/player_saves')return ok(rows.has(id)?[structuredClone(rows.get(id))]:[]);
 if(path.pathname==='/rest/v1/rpc/save_player_game'){
  const old=rows.get(id);if((old?.revision||0)!==body.p_expected_revision)return ok({message:'SAVE_CONFLICT'},409);
  const row={save:body.p_save,revision:(old?.revision||0)+1,updated_at:new Date().toISOString()};rows.set(id,row);return ok([{revision:row.revision,updated_at:row.updated_at}]);
 }
 return ok({},404);
 }};}
test('secret keys rejected and unconfigured mode is explicit',()=>{assert.equal(new CloudAccount({},{storage:storage()}).enabled,false);assert.throws(()=>publicConfig({...config,publishableKey:'sb_secret_x'}));const jwt='x.'+Buffer.from(JSON.stringify({role:'service_role'})).toString('base64url')+'.x';assert.throws(()=>publicConfig({...config,publishableKey:jwt}));});
test('account local save keys never overlap',async()=>{const mem=storage(),s=service(),a=new CloudAccount(config,{storage:mem,fetcher:s.fetcher});await a.login('a@example.com','password123');a.install(save(100));const key=a.saveKey;await a.logout();await a.login('b@example.com','password456');assert.notEqual(a.saveKey,key);assert.equal(a.local(),null);assert.equal(JSON.parse(mem.getItem(key)).profile.coins,100);});
test('signup waits for email verification and passwords never enter browser storage',async()=>{const mem=storage(),s=service(),a=new CloudAccount(config,{storage:mem,fetcher:s.fetcher});assert.equal(await a.signup('a@example.com','password123','https://game.example'),false);assert.equal(a.user,null);assert.equal(mem.getItem('spirit-online-session-v1'),null);await a.login('a@example.com','password123');assert(!mem.getItem('spirit-online-session-v1').includes('password123'));});
test('remote revisions prevent overwriting another device',async()=>{const s=service(),a=new CloudAccount(config,{storage:storage(),fetcher:s.fetcher}),b=new CloudAccount(config,{storage:storage(),fetcher:s.fetcher});await a.login('a@example.com','password123');await a.read();await a.upload(save(10));await b.login('a@example.com','password123');await b.read();await a.upload(save(20));await assert.rejects(b.upload(save(30)),e=>e.code==='SAVE_CONFLICT');assert.equal(s.rows.get(a.user.id).save.profile.coins,20);await b.read();await b.upload(save(30));assert.equal(b.revision,3);});
test('request always uses verified session identity and declared expected revision',async()=>{const s=service(),a=new CloudAccount(config,{storage:storage(),fetcher:s.fetcher});await assert.rejects(a.upload(save()));await a.login('a@example.com','password123');await a.read();await a.upload(save());const request=s.calls.at(-1);assert.equal(request.opt.headers.Authorization,'Bearer '+a.user.id);assert.equal(JSON.parse(request.opt.body).p_expected_revision,0);assert(!('user_id' in JSON.parse(request.opt.body)));});
test('record comparison ignores JSON key order and save timestamp only',()=>{const a=save(),b={position:a.position,profile:a.profile,world:a.world,saved_at:999,version:1};assert(sameSave(a,b));assert(!sameSave(a,save(50)));});
test('invalid saves never upload and local/cloud conflicts require choice',async()=>{const s=service(),a=new CloudAccount(config,{storage:storage(),fetcher:s.fetcher});await a.login('a@example.com','password123');await assert.rejects(a.upload({version:1}));assert(a.needsChoice(save(10),{save:save(20)}));assert(!a.needsChoice(save(10),{save:save(10)}));});
