extends RefCounted
var m
var enabled=false
var direction=Vector2i.ZERO
var refs={}
var textures={}
var sent_textures={}
func _init(main):m=main
func setup():
 enabled=OS.has_feature("web") and bool(JavaScriptBridge.eval("window.SPIRIT_MOBILE===true"))
 if enabled:
  RenderingServer.viewport_set_render_direct_to_screen(m.get_viewport().get_viewport_rid(),true)
  JavaScriptBridge.eval("window.spiritMobileTextures={};")
  var scope=str(JavaScriptBridge.eval("window.SPIRIT_SAVE_SCOPE||''"))
  var pattern=RegEx.new();pattern.compile("^(guest|user-[a-f0-9-]{36})$")
  if pattern.search(scope):
   m.web_save_key="spirit-isles-save-v1:"+scope;m.save_path="user://accounts/"+scope+"/chapter1-save.json"
   DirAccess.make_dir_recursive_absolute("user://accounts/"+scope)
func handle(cmd):
 if not enabled:return
 match cmd.kind:
  "mobile_ui":publish()
  "mobile_direction":direction=Vector2i(clampi(int(cmd.get("x",0)),-1,1),clampi(int(cmd.get("y",0)),-1,1));if direction.x!=0:direction.y=0
  "mobile_resize":
   var width=clampf(float(cmd.get("width",936)),220,936);var height=clampf(float(cmd.get("height",580)),150,580)
   m.world_view.area_rect=Rect2(16,96,width,height);m.world_view.size=Vector2(width,height)
  "mobile_interact":
   direction=Vector2i.ZERO
   if m.modal_kind=="dialog":m.close_overlay()
   elif m.modal_kind=="":
    var p=m.player();var nearest={};var best=2
    for e in m.rules.data.entities(p.area):
     var distance=m.rules.distance(p,e)
     if distance<best:best=distance;nearest=e
    if not nearest.is_empty():m._send_command({"kind":"interact","id":nearest.id})
   elif is_instance_valid(m.battle_intro):m.battle_intro.skip()
  "mobile_click","mobile_input":
   var reference=refs.get(str(cmd.get("id","")))
   if reference==null or not is_instance_valid(reference.get_ref()):return
   var node=reference.get_ref()
   if not node.is_visible_in_tree():return
   if cmd.kind=="mobile_click" and node is Button and not node.disabled:direction=Vector2i.ZERO;node.pressed.emit()
   elif cmd.kind=="mobile_input":
    if node is SpinBox:
     node.value=clampf(float(cmd.get("value",node.value)),node.min_value,node.max_value);node.get_line_edit().text=str(node.value)
    elif node is OptionButton:
     var i=int(cmd.get("value",-1))
     if i>=0 and i<node.item_count and not node.is_item_disabled(i):node.select(i);node.item_selected.emit(i)
    elif node is Range:node.value=clampf(float(cmd.get("value",node.value)),node.min_value,node.max_value)
    elif node is LineEdit and node.editable:node.text=str(cmd.get("value","")).left(node.max_length if node.max_length>0 else 4096);node.text_changed.emit(node.text)
  "mobile_navigate":m.journal_ui.navigate(str(cmd.get("area",m.player().area)),str(cmd.get("entity","")))
  "mobile_export":
   if m.mode!="solo" and not m.player().get("battle","").is_empty():return
   m.save_game()
   if m.last_save_message.contains("✓"):
    JavaScriptBridge.eval("window.spiritMobileSave="+JSON.stringify(FileAccess.get_file_as_string(m.save_path))+";")
  "mobile_import":import_save(str(cmd.get("value","")))
func import_save(raw):
 if m.mode!="solo" or not m.player().get("battle","").is_empty():m.show_notice("目前不能匯入","請先結束戰鬥並離開連線房間。");return
 if raw.length()>8*1024*1024:m.show_notice("檔案太大","請選擇靈嶼匯出的JSON存檔。");return
 var save=JSON.parse_string(raw)
 if not save is Dictionary or int(save.get("version",0))!=1 or not save.get("profile") is Dictionary or not save.get("world") is Dictionary or not save.get("position") is Dictionary:m.show_notice("存檔格式不正確","原有存檔沒有變更。");return
 if not save.profile.get("party",[]) is Array or save.profile.party.is_empty() or save.profile.party.size()>4 or not save.profile.get("bench",[]) is Array or save.profile.bench.size()>120:m.show_notice("精靈資料不正確","原有存檔沒有變更。");return
 for mon in save.profile.party+save.profile.bench:
  if not mon is Dictionary or not str(mon.get("family","")) in m.rules.data.IDS:m.show_notice("精靈資料不正確","原有存檔沒有變更。");return
 # Reject malformed nested world data before replacing either storage copy.
 if not save.world.get("flags",{}) is Dictionary or not save.world.get("adventure",{}) is Dictionary:m.show_notice("世界資料不正確","原有存檔沒有變更。");return
 save.saved_at=Time.get_unix_time_from_system();var encoded=JSON.stringify(save)
 var old=FileAccess.get_file_as_string(m.save_path) if FileAccess.file_exists(m.save_path) else ""
 if not old.is_empty():var backup=FileAccess.open(m.save_path+".before-import",FileAccess.WRITE);if backup:backup.store_string(old)
 var file=FileAccess.open(m.save_path,FileAccess.WRITE)
 if not file:m.show_notice("無法寫入存檔","請檢查瀏覽器儲存空間。");return
 file.store_string(encoded);file.close()
 JavaScriptBridge.eval("try{localStorage.setItem("+JSON.stringify(m.web_save_key)+","+JSON.stringify(encoded)+");}catch(error){}");JavaScriptBridge.force_fs_sync();m.load_game()
func texture_key(texture):
 if texture is AtlasTexture:return str(texture.atlas.resource_path)+":"+str(texture.region)
 return texture.resource_path if texture.resource_path!="" else str(texture.get_instance_id())
func picture(texture):
 if texture==null:return ""
 var key=texture_key(texture)
 if not sent_textures.has(key):
  var url=JavaScriptBridge.eval("(window.spiritMobileAssetIndex||{})["+JSON.stringify(key)+"]||''")
  if url is String and url!="":
   JavaScriptBridge.eval("window.spiritMobileTextures["+JSON.stringify(key)+"]="+JSON.stringify(url)+";");sent_textures[key]=true;return key
  JavaScriptBridge.eval("(window.spiritMobileMissingAssets||=[]).push("+JSON.stringify(key)+");")
 elif not textures.has(key):return key
 if not textures.has(key):
  var image=texture.get_image()
  if image==null or image.is_empty():return ""
  textures[key]="data:image/png;base64,"+Marshalls.raw_to_base64(image.save_png_to_buffer())
 if not sent_textures.has(key):JavaScriptBridge.eval("window.spiritMobileTextures["+JSON.stringify(key)+"]="+JSON.stringify(textures[key])+";");sent_textures[key]=true
 return key
func tree(node,path="root"):
 if not node is Control or not node.visible or node is ScrollBar:return {}
 var id=str(node.get_instance_id());refs[id]=weakref(node)
 var data={"id":id,"key":path,"kind":"column","children":[]}
 if node.get_script()!=null and node.get_script().resource_path=="res://src/circuit_board.gd":
  data.kind="circuit";data["connected"]=node.network.connected
  for i in range(9):data.children.append(tree(node.get_child(i),path+"/"+str(i)))
  return data
 if node.get_script()!=null and node.get_script().resource_path=="res://src/circuit_tile.gd":
  data.merge({"kind":"wire","mask":node.mask,"powered":node.powered,"disabled":node.disabled},true);return data
 if node is SpinBox:data.merge({"kind":"number","value":node.value,"min":node.min_value,"max":node.max_value,"step":node.step},true);return data
 if node is OptionButton:
  var options=[]
  for i in range(node.item_count):options.append({"text":node.get_item_text(i),"disabled":node.is_item_disabled(i)})
  data.merge({"kind":"select","options":options,"value":node.selected,"disabled":node.disabled},true);return data
 if node is Button:
  data.merge({"kind":"button","text":node.text,"tip":node.tooltip_text,"disabled":node.disabled,"icon":picture(node.icon)},true)
  for i in range(node.get_child_count()):
   var child=tree(node.get_child(i),path+"/"+str(i))
   if not child.is_empty():data.children.append(child)
  return data
 if node is LineEdit:data.merge({"kind":"input","value":node.text,"placeholder":node.placeholder_text,"secret":node.secret,"disabled":not node.editable},true);return data
 if node is Label or node is RichTextLabel:
  data.merge({"kind":"text","text":help_text(node.text),"large":node.get_theme_font_size("font_size")>=22},true);return data
 if node is TextureRect:data.merge({"kind":"image","texture":picture(node.texture),"width":node.custom_minimum_size.x,"height":node.custom_minimum_size.y,"gray":node.material is ShaderMaterial},true);return data
 if node is ProgressBar:data.merge({"kind":"progress","value":node.value,"max":node.max_value},true);return data
 if node is Slider:data.merge({"kind":"slider","value":node.value,"min":node.min_value,"max":node.max_value,"step":node.step},true);return data
 if m.modal_kind=="battle" and is_instance_valid(m.battle_widgets.get("player_name")) and node==m.battle_widgets.player_name.get_parent().get_parent():return {}
 if node.get_script()!=null and node.get_script().resource_path=="res://src/battle_stage.gd":
  var p=m.player();var b=m.snapshot.battles.get(p.battle,{})
  if not b.is_empty():data.merge({"kind":"battle","player":picture(m.visuals.sprite_texture(p.party[p.active])),"enemy":picture(m.visuals.sprite_texture(b.enemy)),"player_hp":p.party[p.active].hp,"enemy_hp":b.enemy.hp,"serial":b.get("event_serial",0),"round":b.round,"player_name":m.rules.data.mon_name(p.party[p.active]),"enemy_name":m.rules.data.mon_name(b.enemy),"player_max":m.rules.max_hp(p.party[p.active]),"enemy_max":b.enemy_max,"energy":p.party[p.active].pp,"resonance":m.snapshot.world.resonance},true)
  return data
 if node.get_script()!=null and node.get_script().resource_path=="res://src/map_canvas.gd":data.kind="map";return data
 if node is ScrollContainer and is_instance_valid(m.party_ui.left_scroll) and node==m.party_ui.left_scroll:data.kind="roster"
 elif node is HBoxContainer:data.kind="row"
 elif node is GridContainer:data.kind="grid";data["columns"]=node.columns
 elif node is PanelContainer:data.kind="card"
 for i in range(node.get_child_count()):
  var child=tree(node.get_child(i),path+"/"+str(i))
  if not child.is_empty():data.children.append(child)
 return data
func publish():
 refs={}
 var presentations=m.get_tree().get_nodes_in_group("presentations")
 var busy=is_instance_valid(m.battle_intro) or is_instance_valid(m.evolution_presentation) or not presentations.is_empty()
 var out={"modal":m.modal_kind,"busy":busy,"tree":{},"message":m.player().get("message",{}),"area":m.player().get("area","village"),"actions":[]}
 if busy:
  var nodes=[]
  for presentation in presentations:nodes.append(presentation)
  while not nodes.is_empty():
   var node=nodes.pop_front()
   for child in node.get_children():nodes.append(child)
   if node is Button and node.is_visible_in_tree():out.actions.append(tree(node,"presentation/"+str(node.get_instance_id())))
 if is_instance_valid(m.overlay) and not busy:out.tree=tree(m.overlay.get_child(1))
 JavaScriptBridge.eval("window.spiritMobileTree="+JSON.stringify(out)+";")

func help_text(text):
 if text.begins_with("方向鍵／WASD走路"):return "手機左下方向盤可持續走路，放開就停；右下「互動」可和旁邊人物對話。也能點地面或物件自動走近。上方工具列開啟精靈、背包、任務與地圖；手機設定可切換較大文字。"
 if text.begins_with("Windows版可建立最多2人的房間"):return "手機可以加入Windows或Mac房主，最多兩人。請先啟動房主桌面遊戲，再輸入ws://房主IP:8877。跨國可透過Tailscale；HTTPS網站需要wss://安全位址。上方「存檔」儲存進度；從「手機設定」匯出JSON備份，換裝置時再匯入。"
 return text

func notify(title,text="",kind="info"):
 JavaScriptBridge.eval("window.dispatchEvent(new CustomEvent('spirit-notice',{detail:"+JSON.stringify({"title":title,"text":text,"kind":kind})+"}));")
