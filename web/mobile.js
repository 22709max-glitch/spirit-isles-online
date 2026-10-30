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
new ResizeObserver(resize).observe($('stage'));
window.addEventListener('resize',()=>{release();resize();});
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
function render(node){
 let el;
 switch(node.kind){
 case 'text':el=document.createElement('p');el.className='m-text'+(node.large?' large':'');el.textContent=node.text;break;
 case 'button':el=document.createElement('button');el.className='m-button';el.disabled=node.disabled;el.title=node.tip||'';if(node.icon)el.append(image(node.icon));if(node.text)el.append(document.createTextNode(node.text));for(const child of node.children||[])el.append(render(child));el.setAttribute("aria-label",node.text||node.tip||"選擇精靈");el.onclick=()=>{command({kind:'mobile_click',id:node.id});setTimeout(poll,80);};break;
 case 'image':el=image(node.texture,'m-image'+(node.gray?' gray':''));el.style.setProperty('--iw',Math.min(node.width||180,300)+'px');el.style.setProperty('--ih',Math.min(node.height||110,210)+'px');break;
 case 'input':case 'number':el=document.createElement('input');el.className='m-input'+(node.kind==='number'?' m-number':'');el.type=node.kind==='number'?'number':node.secret?'password':'text';el.value=node.value;el.placeholder=node.placeholder||'';el.disabled=node.disabled;el.autocomplete='off';el.setAttribute('aria-label',node.placeholder|| (node.kind==='number'?'數量或數值':'輸入欄位'));if(node.kind==='number'){el.min=node.min;el.max=node.max;el.step=node.step;}el.oninput=()=>command({kind:'mobile_input',id:node.id,value:el.value});break;
 case 'select':el=document.createElement('select');el.className='m-select';node.options.forEach((o,i)=>{const option=document.createElement('option');option.textContent=o.text;option.value=i;option.disabled=o.disabled;el.append(option);});el.value=node.value;el.disabled=node.disabled;el.setAttribute('aria-label',node.options[node.value]?.text||'選擇分類');el.onchange=()=>{command({kind:'mobile_input',id:node.id,value:el.value});setTimeout(poll,80);};break;
 case 'progress':el=document.createElement('progress');el.className='m-progress';el.value=node.value;el.max=node.max||1;break;
 case 'slider':el=document.createElement('input');el.type='range';el.min=node.min;el.max=node.max;el.step=node.step;el.value=node.value;el.oninput=()=>command({kind:'mobile_input',id:node.id,value:el.value});break;
 case 'map':el=document.createElement('div');drawMap(el);break;
 case 'battle':{el=document.createElement('div');el.className='m-duel';const round=document.createElement('p');round.className='duel-round';round.textContent=`第${node.round}回合 · 能量 ${node.energy}/12 · 共鳴 ${node.resonance}%`;el.append(round);const arena=document.createElement('div');arena.className='m-battle';
 const sides=[['player',node.player_name,node.player_hp,node.player_max],['enemy',node.enemy_name,node.enemy_hp,node.enemy_max]];
 for(const [side,name,hp,max] of sides){const card=document.createElement('div');card.className='duel-mon';const sprite=image(node[side]);if(lastBattle[side+'_hp']>hp)sprite.classList.add('hit');if(side==='player'&&lastBattle.enemy_hp>node.enemy_hp)sprite.classList.add('strike');card.append(sprite);const info=document.createElement('div'),title=document.createElement('p'),health=document.createElement('p'),bar=document.createElement('progress');title.textContent=name;health.textContent=`HP ${hp}/${max}`;bar.value=hp;bar.max=max;bar.className='m-progress';info.append(title,health,bar);card.append(info);arena.append(card);}el.append(arena);lastBattle=node;break;}

 default:el=document.createElement('div');el.className='m-'+(node.kind||'column');for(const child of node.children||[])el.append(render(child));
 }
 el.dataset.key=node.key;return el;
}
function update(){
 const snapshot=window.spiritMobileTree,s=window.spiritState;if(!snapshot||!s)return;
 const p=s.room.players[s.local_id];if(!p)return;$('location').textContent=window.spiritMaps?.[p.area]?.name||p.area;$('statusline').textContent=s.save_message||p.message?.split('\n')[0]||'';
 const cinema=$('cinematic-controls');const actions=snapshot.actions||[];const actionSignature=JSON.stringify(actions);if(cinema.dataset.signature!==actionSignature){cinema.replaceChildren(...actions.map(render));cinema.dataset.signature=actionSignature;}cinema.hidden=!snapshot.busy||!actions.length;
 const visible=!!snapshot.tree?.id&&!snapshot.busy;$('hud').hidden=visible||snapshot.busy||!p.ready;
 if(visible){
  const signature=JSON.stringify(snapshot.tree);
  if(signature!==treeSignature){
   const active=$('menu').contains(document.activeElement)?document.activeElement:null,focus=active?{key:active.dataset.key,value:active.value,start:active.selectionStart,end:active.selectionEnd}:null;
   const top=$('menu').scrollTop,rosterTop=$('menu').querySelector('.m-roster')?.scrollTop||0,changed=lastModal!==snapshot.modal;
   $('menu').replaceChildren(render(snapshot.tree));$('menu').hidden=false;
   $('menu').scrollTop=changed?0:top;const roster=$('menu').querySelector('.m-roster');if(roster)roster.scrollTop=changed?0:rosterTop;
   if(focus){const match=[...$('menu').querySelectorAll('input')].find(e=>e.dataset.key===focus.key);if(match){match.value=focus.value;match.focus({preventScroll:true});try{match.setSelectionRange(focus.start,focus.end);}catch{}}}
   treeSignature=signature;lastModal=snapshot.modal;renderEpoch++;
  }else $('menu').hidden=false;
 }else{$('menu').hidden=true;treeSignature='';lastModal='';}
 if(snapshot.busy!==update.busy){update.busy=snapshot.busy;resize();}
}
function poll(){if(!window.spiritReady)return;command({kind:'mobile_ui'});update();}
setInterval(poll,350);
window.spiritMobileDebug={command,poll,resize,get renderEpoch(){return renderEpoch;}};
$('play').onclick=async()=>{
 $('play').disabled=true;$('load-note').textContent='正在載入遊戲，第一次約需下載105MB，建議使用Wi-Fi。';
 try{await window.startMobileEngine((current,total)=>{if(total){$('load-progress').value=current;$('load-progress').max=total;$('load-note').textContent=`正在載入 ${Math.round(current/total*100)}% · 第一次載入較久`;}});booted=true;$('start').hidden=true;desiredSize=null;resize();poll();}
 catch(error){$('play').disabled=false;$('play').textContent='重新載入';$('load-note').textContent='無法啟動：'+error.message+'\n請使用支援WebGL 2的新版Safari或Chrome，並確認網路連線。';}
};
