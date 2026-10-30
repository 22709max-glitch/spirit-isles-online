'use strict';
window.SPIRIT_MOBILE=true;
const $=id=>document.getElementById(id);
let booted=false,treeSignature='',lastModal='',lastBattle={},desiredSize=null,padPointer=null,renderEpoch=0;
const command=c=>{if(window.spiritAction)window.spiritAction(JSON.stringify(c));};
const menu=name=>{release();command({kind:'menu',name});poll();};
function release(){padPointer=null;command({kind:'mobile_direction',x:0,y:0});}
function resize(){
 const stage=$('stage').getBoundingClientRect(),busy=window.spiritMobileTree?.busy;
 const w=busy?1280:936,h=busy?800:580,scale=Math.min(stage.width/w,stage.height/h);
 const sourceWidth=busy?1280:stage.width/scale,sourceHeight=busy?800:stage.height/scale;
 // Fit a true camera viewport to the available screen, rather than crop the player away.
 const gameScale=busy?scale:Math.max(stage.width/936,stage.height/580);
 const width=busy?1280:stage.width/gameScale,height=busy?800:stage.height/gameScale;
 Object.assign($('canvas').style,{width:1280*gameScale+'px',height:800*gameScale+'px',left:busy?(stage.width-1280*gameScale)/2+'px':-16*gameScale+'px',top:busy?(stage.height-800*gameScale)/2+'px':-96*gameScale+'px'});
 const next=[Math.round(width),Math.round(height)];
 if(!busy&&window.spiritReady&&JSON.stringify(next)!==JSON.stringify(desiredSize)){desiredSize=next;command({kind:'mobile_resize',width:next[0],height:next[1]});}
}
let viewportWidth=window.innerWidth;
function viewport(){
 const height=Math.round(window.visualViewport?.height||window.innerHeight);
 document.documentElement.style.setProperty('--app-height',Math.max(180,height)+'px');if(Math.abs(window.innerWidth-viewportWidth)>10)release();viewportWidth=window.innerWidth;resize();
}
new ResizeObserver(resize).observe($('stage'));
window.visualViewport?.addEventListener('resize',viewport);window.visualViewport?.addEventListener('scroll',()=>{if(window.visualViewport.offsetTop>0)window.scrollTo(0,0);});viewport();
window.addEventListener('resize',viewport);window.addEventListener('orientationchange',release);
document.addEventListener('visibilitychange',()=>{if(document.hidden)release();});
window.addEventListener('blur',release);window.addEventListener('pagehide',release);
document.addEventListener('pointercancel',release);
for(const button of document.querySelectorAll('[data-dir]')){
 const vectors={up:[0,-1],down:[0,1],left:[-1,0],right:[1,0]};
 button.addEventListener('pointerdown',e=>{e.preventDefault();release();padPointer=e.pointerId;button.setPointerCapture(e.pointerId);const [x,y]=vectors[button.dataset.dir];command({kind:'mobile_direction',x,y});});
 for(const type of ['pointerup','lostpointercapture'])button.addEventListener(type,e=>{if(e.pointerId===padPointer)release();});
}
$('interact').onclick=()=>command({kind:'mobile_interact'});
$('target').onclick=()=>command({kind:'navigate_quest'});
for(const button of document.querySelectorAll('[data-menu]'))button.onclick=()=>menu(button.dataset.menu);
$('save').onclick=()=>{release();command({kind:'save'});};
$('tools-open').onclick=()=>{release();$('tools').hidden=false;};
$('tools-close').onclick=()=>$('tools').hidden=true;
$('back').onclick=()=>{release();command({kind:'back'});poll();};
$('fullscreen').onclick=async()=>{try{if(!document.fullscreenElement)await document.documentElement.requestFullscreen();else await document.exitFullscreen();}catch{$('tool-note').textContent='這個瀏覽器不支援全螢幕；仍可直接遊玩。iPhone可用Safari「加入主畫面」。'}resize();};
$('large-text').onclick=()=>{document.body.classList.toggle('large-text');localStorage.setItem('spirit-mobile-large-text',document.body.classList.contains('large-text')?'1':'0');};
try{document.body.classList.toggle('large-text',localStorage.getItem('spirit-mobile-large-text')==='1');}catch{}
$('export-save').onclick=async()=>{
 window.spiritMobileSave=null;command({kind:'mobile_export'});
 for(let i=0;i<30&&!window.spiritMobileSave;i++)await new Promise(r=>setTimeout(r,100));
 if(!window.spiritMobileSave){$('tool-note').textContent='請先結束戰鬥，再匯出存檔。';return;}
 const blob=new Blob([window.spiritMobileSave],{type:'application/json'});const url=URL.createObjectURL(blob),a=document.createElement('a');a.href=url;a.download='SpiritIsles-save-'+new Date().toISOString().slice(0,10)+'.json';a.click();setTimeout(()=>URL.revokeObjectURL(url),30000);$('tool-note').textContent='已匯出JSON存檔。請保存到手機的「檔案」或雲端硬碟。';
};
$('import-save').onclick=()=>$('file-input').click();
$('file-input').onchange=async()=>{
 const file=$('file-input').files[0];if(!file)return;
 if(file.size>8*1024*1024){$('tool-note').textContent='檔案太大，請選擇遊戲匯出的JSON存檔。';return;}
 let raw=await file.text();try{const s=JSON.parse(raw);if(s.version!==1||!s.profile||!s.world||!s.position)throw Error();}catch{$('tool-note').textContent='格式不正確，原存檔沒有變更。';return;}
 if(!confirm('匯入會替換這個瀏覽器的目前進度。建議先匯出備份，確定匯入？'))return;
 command({kind:'mobile_import',value:raw});$('tools').hidden=true;$('file-input').value='';poll();
};
function image(key,cls=''){const img=document.createElement('img');img.src=window.spiritMobileTextures?.[key]||'';img.className=cls;img.alt='';img.draggable=false;return img;}
function drawMap(container){
 const s=window.spiritState,p=s?.room.players[s.local_id],map=window.spiritMaps?.[p?.area];if(!map)return;
 const svg=document.createElementNS('http://www.w3.org/2000/svg','svg');svg.classList.add('m-map');svg.setAttribute('viewBox',`0 0 ${map.size[0]} ${map.size[1]}`);
 const rect=(x,y,w,h,color)=>{const n=document.createElementNS(svg.namespaceURI,'rect');for(const [k,v] of Object.entries({x,y,width:w,height:h,fill:color}))n.setAttribute(k,v);svg.append(n);};rect(0,0,...map.size,'#466457');
 for(const k of ['buildings','groves','water'])for(const b of map[k]||[])rect(b[0],b[1],b[2],b[3],k==='water'?'#4c86a4':'#243c43');
 for(const e of [...map.entities,...map.enemies]){const n=document.createElementNS(svg.namespaceURI,'circle');n.setAttribute('cx',e.x+.5);n.setAttribute('cy',e.y+.5);n.setAttribute('r',.55);n.setAttribute('fill',e.kind==='route_portal'?'#9ee7e0':e.kind==='wild'?'#e78a85':'#e7c881');svg.append(n);}
 for(const [id,peer] of Object.entries(s.room.players))if(peer.area===p.area)rect(peer.x,peer.y,1,1,id===s.local_id?'#fff':'#6fc9ff');container.append(svg);
 const list=document.createElement('div');list.className='map-places';for(const e of map.entities){if(['wild','adventure_enemy'].includes(e.kind))continue;const b=document.createElement('button');b.textContent=e.label||e.name||e.id;b.onclick=()=>{command({kind:'mobile_navigate',area:p.area,entity:e.id});poll();};list.append(b);}container.append(list);
}
const layoutState={cache:new Map(),next:new Map(),roles:new Map(),page:'',scrolls:new Map(),lists:new Map(),partyTab:'總覽',collection:'party',detailsOnly:false,focusDetail:false,signature:''};
function syncChildren(parent,children){
 let at=parent.firstChild;
 for(const child of children){if(child===at)at=at.nextSibling;else parent.insertBefore(child,at);}
 while(at){const next=at.nextSibling;parent.removeChild(at);at=next;}
}
function elementFor(node,tag='div'){
 let el=layoutState.cache.get(node.key);
 if(!el||el.tagName.toLowerCase()!==tag||el.dataset.kind!==node.kind){el=document.createElement(tag);el.dataset.kind=node.kind;el.dataset.key=node.key;}
 layoutState.next.set(node.key,el);el.dataset.action=node.id||'';return el;
}
function nativeClick(node){
 if(document.activeElement?.matches('input,select,textarea'))document.activeElement.blur();
 if(node.text?.startsWith('倉庫 ')){layoutState.collection='bench';layoutState.detailsOnly=false;}if(node.text?.startsWith('同行隊伍 ')){layoutState.collection='party';layoutState.detailsOnly=false;}
 if(node.tip?.includes('點選查看詳情')){layoutState.focusDetail=true;layoutState.detailsOnly=true;}
 if(['總覽','招式','培養','進化','裝備','整理'].includes(node.text))layoutState.partyTab=node.text;
 command({kind:'mobile_click',id:node.id});setTimeout(poll,90);
}
function flatText(node){return [node.text||'',...(node.children||[]).map(flatText)].join(' ');}
function listState(node){const key=layoutState.page+':'+node.key;if(!layoutState.lists.has(key))layoutState.lists.set(key,{page:0,query:''});return layoutState.lists.get(key);}
function listControls(node,total,pages,state,suffix){
 const n={key:node.key+'/pager-'+suffix,kind:'pager'},el=elementFor(n);el.className='list-pager';
 const prev=document.createElement('button'),next=document.createElement('button'),label=document.createElement('span');prev.textContent='上一頁';next.textContent='下一頁';prev.disabled=state.page<=0;next.disabled=state.page>=pages-1;label.textContent=`${state.page+1} / ${pages} · ${total} 項`;
 const turn=delta=>{state.page+=delta;treeSignature='';poll();const body=$('menu-body');body.scrollTop=0;};prev.onclick=()=>turn(-1);next.onclick=()=>turn(1);syncChildren(el,[prev,label,next]);return el;
}
function renderChildren(node,el){
 const all=node.children||[],cards=all.filter(n=>n.kind==='card');
 const paginate=(node.kind==='grid'&&layoutState.page!=='adventure'&&all.length>12&&!all.every(n=>n.kind==='button'))||cards.length>12;
 if(!paginate){syncChildren(el,all.map(render));return;}
 if(node.kind==='grid')el.className='m-column m-paginated';
 const state=listState(node),collection=node.kind==='grid'?all:cards,searchable=layoutState.page==='workshop';
 let filtered=collection;if(searchable&&state.query)filtered=collection.filter(n=>flatText(n).toLowerCase().includes(state.query.toLowerCase()));
 const pages=Math.max(1,Math.ceil(filtered.length/12));state.page=Math.min(state.page,pages-1);const selected=filtered.slice(state.page*12,state.page*12+12),nodes=[];
 if(searchable){const key={key:node.key+'/list-search',kind:'list-search'},input=elementFor(key,'input');input.className='m-input m-list-search';input.placeholder='搜尋配方或材料';input.setAttribute('aria-label','搜尋配方或材料');if(document.activeElement!==input)input.value=state.query;input.oninput=()=>{state.query=input.value;state.page=0;treeSignature='';poll();};nodes.push(input);}
 if(node.kind!=='grid')nodes.push(...all.filter(n=>n.kind!=='card').map(render));
 nodes.push(listControls(node,filtered.length,pages,state,'top'));
 const groupKey={key:node.key+'/list-items',kind:'list-items'},group=elementFor(groupKey);group.className=node.kind==='grid'?'m-grid':'m-paged-content';syncChildren(group,selected.map(render));nodes.push(group);
 if(!filtered.length){const empty=document.createElement('p');empty.className='m-empty';empty.textContent='沒有符合條件的項目';nodes.push(empty);}
 if(pages>1)nodes.push(listControls(node,filtered.length,pages,state,'bottom'));syncChildren(el,nodes);
}
function pictureNode(node){
 const el=elementFor(node,'img');el.className='m-image'+(node.gray?' gray':'')+(node.width<=36&&node.height<=40?' m-icon':'');
 const src=window.spiritMobileTextures?.[node.texture]||'';if(el.getAttribute('src')!==src)el.src=src;el.alt='';el.draggable=false;el.loading='lazy';el.style.setProperty('--iw',Math.min(node.width||180,260)+'px');el.style.setProperty('--ih',Math.min(node.height||110,180)+'px');return el;
}
function render(node){
 let el;const role=layoutState.roles.get(node.key)||'';
 switch(node.kind){
 case 'text':el=elementFor(node,'p');el.className='m-text'+(node.large?' large':'');if(el.textContent!==node.text)el.textContent=node.text;break;
 case 'button':{
  el=elementFor(node,'button');el.className='m-button'+((node.children||[]).length?' m-creature-button':'')+(node.tip?.startsWith('替換第')?' m-slot-button':'');el.disabled=!!node.disabled;el.title=node.tip||'';el.setAttribute('aria-label',node.text||node.tip||'選擇精靈');el.onclick=()=>nativeClick(node);
  const children=[];
  if(node.icon)children.push(pictureNode({kind:'image',key:node.key+'/icon',texture:node.icon,width:24,height:24}));
  if(node.text){let text=el.querySelector(':scope>.button-caption');if(!text){text=document.createElement('span');text.className='button-caption';}const alias={"返回上一頁":"返回","目前區域":"本區","世界與篇章":"世界","傳送點清單":"傳送點","查地點／NPC":"查地點"};const caption=alias[node.text]||node.text;if(text.textContent!==caption)text.textContent=caption;children.push(text);}
  children.push(...(node.children||[]).map(render));syncChildren(el,children);
  if(['總覽','招式','培養','進化','裝備','整理'].includes(node.text)&&layoutState.page==='party')el.setAttribute('aria-current',String(layoutState.partyTab===node.text));else el.removeAttribute('aria-current');break;
 }
 case 'circuit':{
  el=elementFor(node);el.className='m-column';const label=render({key:node.key+'/label',kind:'text',text:'⚡ 發電機 → 旋轉電線 → 接收器 '+(node.connected?'✓ 已接通':'○ 未接通')});
  const grid=elementFor({key:node.key+'/tiles',kind:'tiles'});grid.className='m-grid m-puzzle m-circuit';syncChildren(grid,node.children.map(render));syncChildren(el,[label,grid]);break;
 }
 case 'wire':{
  el=elementFor(node,'button');el.className='m-button m-wire';el.disabled=!!node.disabled;el.setAttribute('aria-label','旋轉電線 '+(Number(node.key.split('/').pop())+1));el.onclick=()=>nativeClick(node);
  const signature=node.mask+':'+node.powered;if(el.dataset.wire!==signature){el.dataset.wire=signature;const ends=[[50,0],[100,50],[50,100],[0,50]],paths=ends.filter((_,i)=>node.mask&(1<<i)).map(([x,y])=>`<path d="M50 50 L${x} ${y}"/>`).join('');el.innerHTML=`<svg viewBox="0 0 100 100" aria-hidden="true"><g stroke="${node.powered?'#f6cf77':'#a6b7c6'}" stroke-width="10" fill="none">${paths}</g><circle cx="50" cy="50" r="9" fill="${node.powered?'#fff1be':'#acbcca'}"/></svg>`;}break;
 }
 case 'image':el=pictureNode(node);break;
 case 'input':case 'number':
  el=elementFor(node,'input');el.className='m-input'+(node.kind==='number'?' m-number':'');el.type=node.kind==='number'?'number':node.secret?'password':'text';if(document.activeElement!==el)el.value=node.value;el.placeholder=node.placeholder||'';el.disabled=!!node.disabled;el.autocomplete='off';el.setAttribute('aria-label',node.placeholder||'數量或數值');if(node.kind==='number'){el.min=node.min;el.max=node.max;el.step=node.step;}el.oninput=()=>command({kind:'mobile_input',id:el.dataset.action,value:el.value});break;
 case 'select':
  el=elementFor(node,'select');el.className='m-select';
  if(document.activeElement!==el){const signature=JSON.stringify(node.options);if(el.dataset.options!==signature){el.replaceChildren(...node.options.map((o,i)=>{const option=document.createElement('option');option.textContent=o.text;option.value=i;option.disabled=o.disabled;return option;}));el.dataset.options=signature;}el.value=node.value;}
  el.disabled=!!node.disabled;el.setAttribute('aria-label',node.options[node.value]?.text||'選擇分類');el.onchange=()=>{command({kind:'mobile_input',id:el.dataset.action,value:el.value});el.blur();setTimeout(poll,90);};break;
 case 'progress':el=elementFor(node,'progress');el.className='m-progress';el.value=node.value;el.max=node.max||1;break;
 case 'slider':el=elementFor(node,'input');el.type='range';el.min=node.min;el.max=node.max;el.step=node.step;if(document.activeElement!==el)el.value=node.value;el.oninput=()=>command({kind:'mobile_input',id:el.dataset.action,value:el.value});break;
 case 'map':el=elementFor(node);el.className='mobile-local-map';el.replaceChildren();drawMap(el);break;
 case 'battle':{
  el=elementFor(node);el.className='m-duel';
  const round=render({key:node.key+'/round',kind:'text',text:`第${node.round}回合 · 能量 ${node.energy}/12 · 共鳴 ${node.resonance}%`});round.className='duel-round';
  const arena=elementFor({key:node.key+'/arena',kind:'arena'});arena.className='m-battle';const s=window.spiritState,p=s?.room.players[s.local_id],b=s?.room.battles[p?.battle];
  const cards=['player','enemy'].map(side=>{
   const card=elementFor({key:node.key+'/'+side,kind:'duel-mon'});card.className='duel-mon';
   const sprite=pictureNode({key:node.key+'/'+side+'/sprite',kind:'image',texture:node[side],width:80,height:80});
   if(lastBattle[side+'_hp']>node[side+'_hp'])sprite.classList.add('hit');if(side==='player'&&lastBattle.enemy_hp>node.enemy_hp)sprite.classList.add('strike');
   const info=elementFor({key:node.key+'/'+side+'/info',kind:'info'}),level=side==='player'?p?.party[p.active]?.level:b?.enemy.level;
   syncChildren(info,[render({key:node.key+'/'+side+'/name',kind:'text',text:node[side+'_name']+(level?' Lv.'+level:'')}),render({key:node.key+'/'+side+'/hp',kind:'text',text:`HP ${node[side+'_hp']}/${node[side+'_max']}`}),render({key:node.key+'/'+side+'/bar',kind:'progress',value:node[side+'_hp'],max:node[side+'_max']})]);syncChildren(card,[sprite,info]);return card;
  });syncChildren(arena,cards);syncChildren(el,[round,arena]);lastBattle=node;break;
 }
 default:
  el=elementFor(node);el.className='m-'+(node.kind||'column');
  if(node.kind==='row'&&(node.children||[]).length>3&&node.children.every(c=>c.kind==='button'))el.classList.add('m-tabs');
  if(node.kind==='grid'&&layoutState.page==='adventure'&&node.columns>=3&&node.columns<=7&&(node.children||[]).length>=9&&(node.children||[]).every(n=>['button','text'].includes(n.kind)&&(n.text||'').length<=6)){el.classList.add('m-puzzle');el.style.gridTemplateColumns=node.columns===7?'20px repeat(6,minmax(0,1fr))':`repeat(${node.columns},minmax(0,1fr))`;}else el.style.gridTemplateColumns='';
  if(node.children?.[0]?.kind==='image'&&node.children[0].texture?.includes('world-map-v04')&&node.children.slice(1).every(n=>n.kind==='button')){
   el.className='m-world-map';const children=node.children.map(render);const coords=[[.16,.73],[.36,.8],[.65,.83],[.83,.44],[.84,.19],[.39,.14],[.54,.10],[.5,.45],[.68,.61],[.21,.5],[.10,.32],[.12,.1]],state=window.spiritState;
   node.children.slice(1).forEach((n,i)=>{const local=state.room.players[state.local_id],peer=Object.entries(state.room.players).find(([id])=>id!==state.local_id)?.[1],actor=n.text.includes('隊友')?peer:local,map=window.spiritMaps?.[actor?.area],chapter=map?.adventure_chapter||map?.chapter||1,c=coords[chapter-1]||coords[0];children[i+1].style.left=`clamp(48px,${c[0]*100}%,calc(100% - 48px))`;children[i+1].style.top=`clamp(24px,${c[1]*100}%,calc(100% - 24px))`;});syncChildren(el,children);
  }else renderChildren(node,el);
 }
 if(role)for(const cls of role.split(' '))el.classList.add(cls);return el;
}
function markRoles(snapshot,body){
 layoutState.roles=new Map();const content=body.children||[];
 if(snapshot.modal==='start'){const row=content.find(n=>n.kind==='row'&&n.children?.some(c=>c.children?.some(x=>x.kind==='image')));if(row)layoutState.roles.set(row.key,'starter-list');}
 if(snapshot.modal==='party'){
  const row=content.find(n=>n.kind==='row'&&n.children?.length===2&&n.children.every(c=>c.kind==='column'));
  if(row){const roster=row.children[0].children?.find(n=>n.kind==='roster'),first=roster?.children?.[0]?.children?.[0];if(first)layoutState.collection=flatText(first).includes(' · 倉庫')?'bench':'party';layoutState.roles.set(row.key,'party-layout');layoutState.roles.set(row.children[0].key,'party-library'+(layoutState.collection==='bench'?' warehouse-library':'')+(layoutState.detailsOnly?' is-collapsed':''));const detail=row.children[1];layoutState.roles.set(detail.key,'party-detail');const hero=detail.children?.find(n=>n.kind==='row'&&n.children?.[0]?.kind==='image');if(hero)layoutState.roles.set(hero.key,'party-hero');}
 }
}
function renderMenu(snapshot){
 const root=snapshot.tree,container=root.children?.[0]||root,native=container.children||[],head=native[0]?.kind==='row'?native[0]:null;
 let frame=$('menu-head'),body=$('menu-body');
 if(!frame){frame=document.createElement('header');frame.id='menu-head';frame.className='mobile-page-head';body=document.createElement('div');body.id='menu-body';body.className='mobile-page-body';body.tabIndex=-1;$('menu').replaceChildren(frame,body);}
 const changed=layoutState.page!==snapshot.modal;
 if(changed){if(layoutState.page)layoutState.scrolls.set(layoutState.page,body.scrollTop);layoutState.cache=new Map();layoutState.page=snapshot.modal;}
 layoutState.next=new Map();
 const tree={...container,children:head?native.slice(1):native};markRoles(snapshot,tree);
 let title=frame.querySelector('h1');if(!title)title=document.createElement('h1');title.textContent=head?.children?.find(n=>n.kind==='text')?.text||'遊戲選單';
 const actions=(head?.children||[]).filter(n=>n.kind==='button').map(render);let settings=frame.querySelector('.mobile-settings-button');if(!settings){settings=document.createElement('button');settings.className='mobile-settings-button';settings.textContent='⚙';settings.setAttribute('aria-label','手機設定');settings.onclick=()=>$('tools-open').click();}
 syncChildren(frame,[title,...actions,settings]);
 const content=render(tree);
 if(snapshot.modal==='more'){
  const quick=elementFor({kind:'quick',key:'mobile-quick-actions'});quick.className='mobile-quick-actions';
  const options=[['圖鑑',()=>menu('codex')],['培養',()=>menu('training')],['製作',()=>menu('workshop')],['手機設定',()=>$('tools-open').click()],['帳號／雲端',()=>$('account-toolbar').click()]];
  syncChildren(quick,options.map(([text,click],i)=>{const el=elementFor({kind:'quick-button',key:'mobile-quick-'+i},'button');el.textContent=text;el.onclick=click;el.disabled=text==='帳號／雲端'&&$('account-toolbar').disabled;return el;}));syncChildren(body,[quick,content]);
 }else syncChildren(body,[content]);
 const detail=body.querySelector('.party-detail');if(detail){
  let change=detail.querySelector(':scope>.party-change');if(!change){change=document.createElement('button');change.className='party-change';change.textContent='選其他精靈 ↑';change.onclick=()=>{layoutState.detailsOnly=false;treeSignature='';poll();body.scrollTop=0;};detail.insertBefore(change,detail.firstChild);}
 }
 layoutState.cache=layoutState.next;$('menu').dataset.page=snapshot.modal;$('menu').hidden=false;
 if(changed)body.scrollTop=layoutState.scrolls.get(snapshot.modal)||0;
 if(layoutState.focusDetail&&detail){layoutState.focusDetail=false;requestAnimationFrame(()=>{body.scrollTop+=detail.getBoundingClientRect().top-body.getBoundingClientRect().top;});}
}
function update(){
 const snapshot=window.spiritMobileTree,s=window.spiritState;if(!snapshot||!s)return;
 const p=s.room.players[s.local_id];if(!p)return;$('location').textContent=(window.spiritMaps?.[p.area]?.name||p.area)+(p.test_modified?' · 測試模式':'');$('statusline').textContent=s.save_message||p.message?.split('\n')[0]||'';
 const cinema=$('cinematic-controls'),actions=snapshot.actions||[],actionSignature=JSON.stringify(actions);
 if(cinema.dataset.signature!==actionSignature){layoutState.next=new Map(layoutState.cache);syncChildren(cinema,actions.map(render));layoutState.cache=layoutState.next;cinema.dataset.signature=actionSignature;}cinema.hidden=!snapshot.busy||!actions.length;
 const visible=!!snapshot.tree?.id&&!snapshot.busy;$('hud').hidden=visible||snapshot.busy||!p.ready;
 if(visible){const signature=JSON.stringify(snapshot.tree);if(signature!==treeSignature){renderMenu(snapshot);treeSignature=signature;lastModal=snapshot.modal;renderEpoch++;}else $('menu').hidden=false;}
 else{if(layoutState.page&&$('menu-body'))layoutState.scrolls.set(layoutState.page,$('menu-body').scrollTop);$('menu').hidden=true;treeSignature='';}
 if(snapshot.busy!==update.busy){update.busy=snapshot.busy;resize();}
}

let lastUiState=null,lastPollAt=0;
function poll(force=true){
 if(!window.spiritReady)return;
 if(!force&&window.spiritState===lastUiState&&!window.spiritMobileTree?.busy&&Date.now()-lastPollAt<3000)return;
 command({kind:'mobile_ui'});lastUiState=window.spiritState;lastPollAt=Date.now();update();
}
setInterval(()=>{if(!document.hidden)poll(false);},450);
window.spiritMobileDebug={command,poll,resize,get renderEpoch(){return renderEpoch;}};
$('play').onclick=async()=>{
 $('play').disabled=true;$('load-note').textContent='正在載入遊戲，第一次約需下載105MB，建議使用Wi-Fi。';
 try{await window.startMobileEngine((current,total)=>{if(total){$('load-progress').value=current;$('load-progress').max=total;$('load-note').textContent=`正在載入 ${Math.round(current/total*100)}% · 第一次載入較久`;}});booted=true;$('start').hidden=true;desiredSize=null;resize();poll();}
 catch(error){$('play').disabled=false;$('play').textContent='重新載入';$('load-note').textContent='無法啟動：'+error.message+'\n請使用支援WebGL 2的新版Safari或Chrome，並確認網路連線。';}
};
let noticeTimer;
window.addEventListener('spirit-notice',event=>{
 const data=event.detail||{};let toast=$('mobile-toast');
 if(!toast){toast=document.createElement('aside');toast.id='mobile-toast';toast.setAttribute('role','status');document.body.append(toast);}
 const title=document.createElement('strong'),text=document.createElement('span');title.textContent=data.title||'';text.textContent=data.text||'';toast.replaceChildren(title,text);toast.dataset.kind=data.kind||'info';toast.hidden=false;clearTimeout(noticeTimer);noticeTimer=setTimeout(()=>toast.hidden=true,data.kind==='area'?2800:4000);
});
