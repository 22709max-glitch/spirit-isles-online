extends Control

const UISkin=preload("res://src/ui_skin.gd")
var skin
var mobile
var item_ui
var combat_ui
var journal_ui
var travel_ui
const AdventureUI=preload("res://src/adventure_ui.gd")
var adventure_ui
var ui_font_size=16
var ui_history=[]
var current_route={}
var navigating_back=false
var ui_refresh_key=""
var trade_ui
var coop_ui
var gray_shader
const CampaignUI=preload("res://src/campaign_ui.gd")
const AudioManager=preload("res://src/audio_manager.gd")
var campaign_ui
var audio
var people=preload("res://src/people_assets.gd").new()
var outfit_ui
var local_map
var tester_ui
var map_hub
var genetics_ui
var nursery_ui
var gacha_ui
var evolution_ui
var evolution_task_ui
var trial_ui
var last_hatch=""
var evolution_presentation
var last_evolution=""
var tester_marker
var last_discovery=""
var last_ui_nonce=-1
var last_ui_uid=""
const Rules = preload("res://src/rules.gd")
const WorldView = preload("res://src/world_view.gd")
const VisualAssets = preload("res://src/visual_assets.gd")
const BattleStage = preload("res://src/battle_stage.gd")
const BattleIntro = preload("res://src/battle_intro.gd")
var rules = Rules.new()
var snapshot = {}
var local_id = "1"
var mode = "solo"
var dedicated = false
var overlay: Control
var modal_kind = ""
var base_ui: Control
var sidebar: VBoxContainer
var message_label: Label
var pending_area_banner=""
var location_banner
var location_label: Label
var world_view
var font
var visuals
var game_speed=1.0
var visual_time=0.0
var tracked_quest="main"
var party_ui
var boss_ui
var shop_ui
var lookup
var party_target_slot=0
var party_selected_uid=""
var party_confirm={}
var party_feedback=""
var party_scroll
var bench_scroll
var bench_scroll_value=0
var party_swap_uid=""
var party_scroll_value=0
var party_scroll_end=false
var bag_feedback=""
var feedback_pending=""
var feedback_seq=0
var sidebar_key=""
var last_profile={}
var battle_widgets={}
var battle_intro
var battle_seen=""
var battle_completed=""
var codex_query=""
var codex_filter="all"
var codex_type=""
var codex_grid
var codex_scroll
var codex_scroll_value=0
var codex_source="all"
var codex_category="all"
var codex_stages=0
var codex_region=0
var codex_count_label
var textures = {}
var frames = {}
var path: Array = []
var interact_target = ""
var move_clock = 0.0
var network_message = "單人探索"
var pending_profile = {}
var last_move_times = {}
var js_callback
var save_path = "user://chapter1-save.json"
var web_save_key="spirit-isles-save-v1"
var last_save_message = ""
var connection_timer = 0.0
var request_serial = 0
var theme_dark = Color("10262e")

func _ready():
 mobile=preload("res://src/mobile_bridge.gd").new(self);mobile.setup()
 lookup=preload("res://src/location_lookup.gd").new(self)
 shop_ui=preload("res://src/shop_ui.gd").new(self)
 boss_ui=preload("res://src/boss_ui.gd").new(self)
 party_ui=preload("res://src/party_ui.gd").new(self)
 trade_ui=preload("res://src/trade_ui.gd").new(self)
 coop_ui=preload("res://src/coop_ui.gd").new(self)
 name="Main"
 font=load("res://assets/SpiritUI-Regular.otf")
 combat_ui=preload("res://src/combat_ui.gd").new(self);outfit_ui=preload("res://src/outfit_ui.gd").new(self);local_map=preload("res://src/local_map.gd").new(self);tester_ui=preload("res://src/tester_ui.gd").new(self);map_hub=preload("res://src/map_hub.gd").new(self);genetics_ui=preload("res://src/genetics_ui.gd").new(self);nursery_ui=preload("res://src/nursery_ui.gd").new(self);gacha_ui=preload("res://src/gacha_ui.gd").new(self);evolution_ui=preload("res://src/evolution_ui.gd").new(self);evolution_task_ui=preload("res://src/evolution_task_ui.gd").new(self);trial_ui=preload("res://src/trial_ui.gd").new(self);journal_ui=preload("res://src/quest_journal.gd").new(self);travel_ui=preload("res://src/travel_ui.gd").new(self)
 skin=UISkin.new();item_ui=preload("res://src/item_ui.gd").new(self)
 visuals=VisualAssets.new();campaign_ui=CampaignUI.new(self);adventure_ui=AdventureUI.new(self)
 var theme=Theme.new();theme.default_font=font;theme.default_font_size=16
 theme.set_color("font_color","Label",Color("e9efe5"))
 theme.set_color("font_color","Button",Color("e9efe5"))
 theme.set_color("font_disabled_color","Button",Color("829997"))
 theme.set_stylebox("normal","Button",box(Color("203d43"),Color("456361")))
 theme.set_stylebox("hover","Button",box(Color("31594f"),Color("a5ceac")))
 theme.set_stylebox("pressed","Button",box(Color("48795f"),Color("d8ce99")))
 theme.set_stylebox("disabled","Button",box(Color("1c2d33"),Color("2c454a")))
 theme.set_stylebox("normal","LineEdit",box(Color("132e36"),Color("688776")))
 theme.set_color("font_color","LineEdit",Color("e9efe5"))
 skin.install(theme)
 self.theme=theme
 mouse_filter=Control.MOUSE_FILTER_STOP
 multiplayer.peer_connected.connect(_on_peer_connected)
 multiplayer.peer_disconnected.connect(_on_peer_disconnected)
 multiplayer.connected_to_server.connect(_on_connected)
 multiplayer.connection_failed.connect(_on_connection_failed)
 multiplayer.server_disconnected.connect(_on_server_disconnected)
 dedicated="--server" in OS.get_cmdline_user_args()
 if dedicated:
  _start_host(true);return
 audio=AudioManager.new();add_child(audio)
 _load_presentation_settings();_load_ui_settings()
 rules.add_player(1)
 snapshot=rules.room.duplicate(true)
 var backdrop=TextureRect.new();backdrop.texture=skin.texture("screen-bg.svg");backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);backdrop.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(backdrop)
 world_view=WorldView.new();world_view.main=self;add_child(world_view)
 _build_base_ui()
 _refresh()
 show_start()
 if OS.has_feature("web"):
  js_callback=JavaScriptBridge.create_callback(_web_command)
  var win=JavaScriptBridge.get_interface("window");win.spiritAction=js_callback
  JavaScriptBridge.eval("window.spiritMaps="+JSON.stringify(rules.data.maps)+";window.spiritReady=true;")
  _web_sync()
func box(bg,border):
 if skin:return skin.style("panel-warm" if border.r>border.b*1.2 and border.r>.5 else "panel-card",12)
 var style=StyleBoxFlat.new();style.bg_color=bg;style.border_color=border;style.set_border_width_all(1);return style
func label(text,size=16,color=Color("e9efe5")):
 var l=Label.new();l.text=plain_text(str(text));l.add_theme_font_size_override("font_size",ui_size(size));l.add_theme_color_override("font_color",color);return l
func button(text,callback,minsize=Vector2(150,40)):
 var b=Button.new();b.text=plain_text(str(text));b.add_theme_font_size_override("font_size",ui_size(16));b.custom_minimum_size=minsize;b.focus_mode=Control.FOCUS_NONE;b.pressed.connect(callback,CONNECT_DEFERRED)
 if skin:
  if str(text).contains("返回"):b.icon=skin.texture("icon-arrowLeft.png")
  elif str(text)=="關閉":b.icon=skin.texture("icon-cross.png")
  if b.icon:b.expand_icon=true;b.add_theme_constant_override("icon_max_width",15)
 if audio:b.pressed.connect(audio.play.bind("click"))
 return b
func _panel(rect):
 var p=PanelContainer.new();p.position=rect.position;p.size=rect.size;p.add_theme_stylebox_override("panel",skin.style("panel-window",14));return p
func _build_base_ui():
 base_ui=Control.new();base_ui.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR;base_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);base_ui.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(base_ui)
 var title=label("靈 嶼",28,Color("efd39b"));title.position=Vector2(20,8);base_ui.add_child(title)
 var sub=label("群島遠征  /  v0.9.2",14,Color("9db7ad"));sub.position=Vector2(112,20);base_ui.add_child(sub)
 location_label=label("芽灣村",15);location_label.position=Vector2(22,56);base_ui.add_child(location_label)
 var menu=HBoxContainer.new();menu.position=Vector2(410,17);menu.add_theme_constant_override("separation",6);base_ui.add_child(menu)
 for entry in [["精靈","party"],["背包","inventory"],["圖鑑","codex"],["任務","rewards"],["地圖","world_map"],["培養","training"],["製作","workshop"],["更多","more"],["存檔","save"]]:
  var nav=button(entry[0],open_root.bind(entry[1]),Vector2(78,42));nav.icon=skin.nav_icon(entry[1]);nav.expand_icon=true;nav.add_theme_constant_override("icon_max_width",20);nav.add_theme_font_size_override("font_size",15);nav.add_to_group("main_navigation");nav.set_meta("section",entry[1]);menu.add_child(nav)
 var speed=button("1×",cycle_speed,Vector2(70,36));speed.position=Vector2(1190,17);speed.add_to_group("speed_controls");speed.text=_speed_text();speed.tooltip_text="切換 1×、1.5×、2×（Tab）。加速行走與演出，不改傷害與收益。";base_ui.add_child(speed)
 var side=_panel(Rect2(968,96,296,686));base_ui.add_child(side)
 sidebar=VBoxContainer.new();sidebar.add_theme_constant_override("separation",3);side.add_child(sidebar)
 var footer=_panel(Rect2(16,710,936,72));base_ui.add_child(footer)
 message_label=label("",15);message_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;message_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;message_label.max_lines_visible=2;footer.add_child(message_label)
 var chart=button("屬性表（T）",show_type_guide,Vector2(133,24));chart.position=Vector2(818,683);chart.add_theme_font_size_override("font_size",12);base_ui.add_child(chart)
 var minimap=preload("res://src/map_canvas.gd").new();minimap.main=self;minimap.position=Vector2(751,106);minimap.size=Vector2(190,148);base_ui.add_child(minimap)
 tester_marker=label("測試資料／模式",13,Color("ffd48c"));tester_marker.position=Vector2(760,660);tester_marker.visible=false;base_ui.add_child(tester_marker)
 var help=label("WASD 移動   E 互動   點地面走路   F5 存檔   ESC 關閉",13,Color("a9c2ae"));help.position=Vector2(23,686);base_ui.add_child(help)
func player():return snapshot.get("players",{}).get(local_id,{})
func _refresh():
 if dedicated:return
 var p=player()
 if p.is_empty():return
 if audio:audio.set_context(music_context())
 if tester_marker:tester_marker.visible=bool(p.get("tester_unlocked",false)) or bool(p.get("test_modified",false))
 var ev=p.get("evolution_event",{})
 var evkey=p.uid+":"+str(ev.get("serial",0))
 if not ev.is_empty() and evkey!=last_evolution:
  last_evolution=evkey;present_evolution.call_deferred(ev.duplicate(true))
 var hatch=p.get("hatch_event",{})
 var hatch_key=p.uid+":"+str(hatch.get("serial",0))
 if not hatch.is_empty() and hatch_key!=last_hatch:
  last_hatch=hatch_key;present_evolution.call_deferred({"kind":"hatch","before":hatch.mon,"after":hatch.mon})
 var discovery=p.get("discovery",{})
 if not discovery.is_empty() and last_discovery!=discovery.family:
  last_discovery=discovery.family;audio.play("discovery");show_discovery.call_deferred(discovery.duplicate(true))
 location_label.text="%s   /   %s" % [rules.data.maps[p.area].name,rules.data.maps[p.area].subtitle]
 var message=p.message+("\n"+last_save_message if not last_save_message.is_empty() else "")
 if map_hub.walking_to!="":message="正在導航至「"+rules.data.maps[map_hub.walking_to].name+"」 · 手動移動或另選目標可取消。"
 if message_label.text!=message:
  message_label.tooltip_text=plain_text(message);message_label.text=plain_text(message.get_slice("\n",0).left(112));message_label.modulate.a=.35;create_tween().tween_property(message_label,"modulate:a",1.0,.18)
 if not feedback_pending.is_empty() and (mode!="client" or int(p.get("ack",0))>=feedback_seq):
  if feedback_pending=="party":party_feedback=p.message;party_confirm={}
  else:bag_feedback=p.message
  feedback_pending=""
 var guide=rules.data.quest_guide(snapshot.world,p,tracked_quest)
 var nav=rules.data.quest_navigation(snapshot.world,p,tracked_quest)
 var key=JSON.stringify([p.coins,p.bag,p.party,p.active,p.bench.size(),guide,p.area,network_message,snapshot.players.values().map(func(peer):return [peer.uid,peer.area,peer.x,peer.y,peer.battle])])
 if key!=sidebar_key:
  sidebar_key=key
  for child in sidebar.get_children():sidebar.remove_child(child);child.queue_free()
  coop_ui.sidebar(sidebar)
  sidebar.add_child(label("冒險手帳 · 第%d篇" % rules.data.maps[p.area].get("adventure_chapter",rules.data.chapter_for(p.area)),18,Color("f1ddb1")))
  if mode!="solo":sidebar.add_child(label(network_message,12,Color("a6c4b7")))
  sidebar.add_child(label("%s   ·   %d 金幣" % [p.name,p.coins],14))
  sidebar.add_child(label("靈晶 %d　藥 %d　共鳴粉 %d" % [p.bag.seal,p.bag.potion,p.bag.get("dust",0)],12))
  var quest_box=PanelContainer.new();quest_box.add_theme_stylebox_override("panel",box(Color("3f4934"),Color("d8bd76")));sidebar.add_child(quest_box)
  var content=VBoxContainer.new();quest_box.add_child(content)
  content.add_child(label(("主線" if guide.track=="main" else "支線")+" · "+guide.get("status","")+" %d/%d" % [guide.stage,guide.total],12,Color("f6d893")))
  content.add_child(_wrap(guide.title,17,Color("fff0c8")))
  content.add_child(_meter(guide.stage if guide.done else guide.stage-1,guide.total,Color("dfc476"),6))
  content.add_child(_wrap(guide.detail.left(72),11,Color("e0ddbd")))
  if not nav.is_empty():
   content.add_child(_wrap("目標："+nav.label+("（先前往"+nav.destination+"）" if not nav.final else ""),12,Color("c8e2b4")))
   content.add_child(button("前往目標 · 抵達後按 E",focus_quest_target,Vector2(230,32)))
  var claims=rules.quests.claim_count(snapshot.world,p)
  sidebar.add_child(button("可領獎勵 %d 項" % claims if claims>0 else "主線／支線任務手帳",journal_ui.open.bind("claim") if claims>0 else show_quests,Vector2(260,31)))
  sidebar.add_child(label("隊伍  %d／4   共鳴 %d%%" % [p.party.size(),snapshot.world.resonance],14,Color("dce2c4")))
  for i in range(p.party.size()):
   var m=p.party[i];var container=PanelContainer.new();container.add_theme_stylebox_override("panel",box(Color("1b3c42"),Color("597567") if i==p.active else Color("35534f")));sidebar.add_child(container)
   var compact=skin.style("panel-warm" if i==p.active else "panel-card",5);compact.content_margin_left=5;compact.content_margin_right=5;compact.content_margin_top=3;compact.content_margin_bottom=3;container.add_theme_stylebox_override("panel",compact)
   container.tooltip_text="點這隻精靈：補血、換裝、查看潛力";container.gui_input.connect(_sidebar_input.bind(i))
   var row=HBoxContainer.new();row.mouse_filter=Control.MOUSE_FILTER_IGNORE;container.add_child(row);var portrait=art(m,Vector2(50,50));portrait.size_flags_horizontal=Control.SIZE_SHRINK_CENTER;portrait.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(portrait)
   var col=VBoxContainer.new();col.add_theme_constant_override("separation",2);col.size_flags_horizontal=Control.SIZE_EXPAND_FILL;col.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(col)
   var b=button(("> " if i==p.active else "")+rules.data.mon_name(m)+" Lv."+str(int(m.level)),_party_detail.bind(i),Vector2(150,19));b.add_theme_font_size_override("font_size",11)
   for state in ["normal","hover","pressed"]:
    var style=StyleBoxEmpty.new();style.content_margin_top=1;style.content_margin_bottom=1;style.content_margin_left=3;style.content_margin_right=3;b.add_theme_stylebox_override(state,style)
   col.add_child(b)
   col.add_child(_meter(m.hp,rules.max_hp(m),Color("94cfa1"),5))
   col.add_child(_meter(1 if m.level>=current_cap() else m.xp,1 if m.level>=current_cap() else rules.xp_to_next(int(m.level)),Color("84afe8"),4))
   col.add_child(label("HP %d/%d  XP %d/%d" % [m.hp,rules.max_hp(m),m.xp,rules.xp_to_next(int(m.level))],10,Color("b0cbc2")))
  sidebar.add_child(label("已收集 %d／100 · 寄放 %d／120" % [p.dex.size(),p.bench.size()],12,Color("bdd0b8")))
  if rules.data.maps[p.area].get("zone","")=="dungeon" and p.battle.is_empty() and mode!="solo":sidebar.add_child(button("加入同伴首領戰",_send_command.bind({"kind":"join_boss"}),Vector2(240,28)))
 if not last_profile.is_empty() and p.area!=last_profile.get("area",p.area):
  if modal_kind in ["travel","world_map","chapter_map","local_map","area_plan","journal","quest_detail","room_reward","adventure","waypoints"]:close_overlay()
  path=[];interact_target=""
  var location=rules.adventure.defn(p);tracked_quest="side_"+p.area if not location.is_empty() and int(location.variant)>0 else "main"
  pending_area_banner=p.area
  if map_hub.walking_to!="":map_hub.continue_walk.call_deferred()
 if p.ready and not last_profile.get("ready",false):pending_area_banner=p.area
 last_profile=p.duplicate(true)
 if not p.battle.is_empty():
  if not modal_kind in ["battle_switch","tutorial","types","help","tactics","quick","movebook"]:show_battle()
 elif modal_kind=="battle" or (modal_kind in ["tactics","battle_switch","tutorial","help","types","quick"] and battle_seen!="" and p.get("last_battle",{}).get("id","")==battle_seen):show_battle_result()
 elif modal_kind=="shop":
  if shop_ui.stamp()!=ui_refresh_key:shop_ui.open()
 elif modal_kind in ["boss_rematch","boss_drops"]:
  var stamp=JSON.stringify([p.stats,p.party,p.bench,p.message,p.get("rematch_target",{})])
  if stamp!=ui_refresh_key:ui_refresh_key=stamp;boss_ui.open() if modal_kind=="boss_rematch" else boss_ui.rewards()
 elif modal_kind=="party":
  var stamp=JSON.stringify([p.party,p.bench,p.message,p.bag])
  if stamp!=ui_refresh_key:ui_refresh_key=stamp;show_party()
 elif modal_kind in ["world_map","chapter_map","adventure","quick","training","inventory","workshop","rewards","lottery","healing","more","options","legends","legend_shrine","local_map","area_plan","evolution_route","evolution_task","genes","outfits","tester","item_detail","journal","quest_detail","room_reward","movebook","waypoints"]:
  var stamp=JSON.stringify([modal_kind,p.bag,p.party,p.bench,p.eggs,p.message,p.coins,p.get("tester_unlocked",false),p.outfit,p.outfits,snapshot.world.adventure.get("rooms",{}).get(p.area,{}) if modal_kind=="adventure" else {}])
  if stamp!=ui_refresh_key:ui_refresh_key=stamp;adventure_ui.show(modal_kind)
 elif modal_kind=="trade":
  if trade_ui.stamp()!=ui_refresh_key:trade_ui.open()
 elif modal_kind=="nursery":
  var stamp=JSON.stringify([p.eggs,p.nursery_jobs,p.bag,p.party,p.bench,p.message])
  if stamp!=ui_refresh_key:ui_refresh_key=stamp;nursery_ui.open()
 elif modal_kind in ["bag","shop","craft","research","board","nursery","travel","collection","challenges","quests"]:campaign_ui.show(modal_kind)
 if modal_kind=="survey" and p.get("question","").is_empty():close_overlay()
 if p.battle.is_empty() and not p.get("ui_request","").is_empty() and (last_ui_nonce!=int(p.get("ui_nonce",0)) or last_ui_uid!=p.uid):
  last_ui_nonce=int(p.get("ui_nonce",0));last_ui_uid=p.uid
  var requested=p.ui_request
  var aliases={"trade":"trade","adventure":"adventure","world_map":"world_map","healing":"healing","legend_shrine":"legend_shrine","travel":"world_map","craft":"workshop","research":"rewards","board":"rewards","movebook":"movebook","room_reward":"room_reward","tester":"tester","lottery":"lottery","local_map":"local_map","outfits":"outfits","boss_rematch":"boss_rematch"}
  if requested=="genes":genetics_ui.open(str(p.get("genes_uid","")))
  elif requested=="research":campaign_ui.research()
  elif requested=="movebook":combat_ui.movebook(str(p.get("movebook_uid","")))
  elif aliases.has(requested):adventure_ui.show(aliases[requested])
  else:campaign_ui.show(requested)
 if world_view:world_view.queue_redraw()
 _web_sync()
func _meter(value,maximum,color,height=8):
 var bar=ProgressBar.new();bar.min_value=0;bar.max_value=maxf(1,maximum);bar.value=clampf(value,0,bar.max_value);bar.show_percentage=false;bar.custom_minimum_size.y=height;bar.size_flags_horizontal=Control.SIZE_EXPAND_FILL;bar.mouse_filter=Control.MOUSE_FILTER_IGNORE
 var bg=StyleBoxFlat.new();bg.bg_color=Color("101c2c");bg.border_color=Color("52677d");bg.set_border_width_all(1);bg.set_corner_radius_all(4)
 var fill=StyleBoxFlat.new();fill.bg_color=color;fill.set_corner_radius_all(3)
 bar.add_theme_stylebox_override("background",bg);bar.add_theme_stylebox_override("fill",fill);return bar
func _type_row(types,icon_size=22):
 var row=HBoxContainer.new();row.add_theme_constant_override("separation",7)
 for type in types:
  var icon=TextureRect.new();icon.texture=visuals.icon(type);icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;icon.custom_minimum_size=Vector2(icon_size,icon_size);icon.tooltip_text=type+" · 克制 "+"／".join(rules.data.ADVANTAGE.get(type,[]));row.add_child(icon)
  row.add_child(label(type,13,visuals.type_color(type)))
 return row
func quest_navigation():
 if map_hub and map_hub.walking_to!="":
  var gate=rules.travel.next_gate(player(),map_hub.walking_to)
  if not gate.is_empty():return gate
 return rules.data.quest_navigation(snapshot.world,player(),tracked_quest)
func focus_quest_target():
 var job=rules.quests.guide(snapshot.world,player(),tracked_quest)
 if job.get("target","")=="":journal_ui.open();return
 journal_ui.navigate(job.area,job.target)
func show_notice(title,detail=""):
 if mobile and mobile.enabled:mobile.notify(title,detail);return
 if dedicated or modal_kind in ["battle","battle_result","party"]:return
 var card=_panel(Rect2(34,102,420,70));card.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(card)
 var col=VBoxContainer.new();col.mouse_filter=Control.MOUSE_FILTER_IGNORE;card.add_child(col);col.add_child(label(title,20,Color("ffe2a3")));col.add_child(label(detail,12,Color("bbd5c0")))
 card.modulate.a=0;var tween=create_tween();tween.tween_property(card,"modulate:a",1.0,.2);tween.tween_interval(1.5);tween.tween_property(card,"modulate:a",0.0,.3);tween.tween_callback(card.queue_free)
func _speed_text():return (str(int(game_speed)) if game_speed==int(game_speed) else str(game_speed))+"×"
func _load_presentation_settings():
 var config=ConfigFile.new()
 if config.load("user://presentation.cfg")==OK:game_speed=clampf(float(config.get_value("play","speed",1.0)),1.0,2.0)
 Engine.time_scale=game_speed
func cycle_speed():
 game_speed=1.5 if game_speed<1.25 else (2.0 if game_speed<1.75 else 1.0);Engine.time_scale=game_speed
 var config=ConfigFile.new();config.set_value("play","speed",game_speed);config.save("user://presentation.cfg")
 for b in get_tree().get_nodes_in_group("speed_controls"):
  if is_instance_valid(b):b.text=_speed_text()
 _web_sync()
func show_tutorial():
 var v=campaign_ui._page("tutorial","操作與戰鬥教學 · 隨時從「更多 → 操作說明」查看")
 for card in [["先從哪裡開始？","選好夥伴後，從村莊主線道路出發，或點上方「地圖」規劃步行路線。未探索地區不能直接傳送，先踩亮傳送石。進入後到任務控制臺按E，查看機關與剩下的目標。完成8個主線區域後開放下一篇；每個區域都有可自由往返的三條探索支線。每篇交錯安排不同機關，不會連續八區都接線。"],["移動與互動","方向鍵／WASD走路，E與旁邊角色互動；點人物或物件可自動走近。Tab切換1倍／1.5倍／2倍速，ESC關閉視窗。第二篇按C切換慢走。"],["突擊、屬性與專屬招式","突擊不耗能量；主屬性Lv.5學會基礎招式，Lv.18學會進階招式，Lv.36學會高階招式；第二屬性的學習等級另列在配招頁。每隻最多配置4招，點右側精靈 → 配招可替換。技能果實可教會額外屬性的招式，已學會的不會消失。"],["守勢、換人與首領","守勢回2能量並降低60%傷害。首領每第三回合會重擊，當回合要留意守勢。倒下後會暫停，讓你自行選替補；替補不消耗回合。按T可隨時開屬性表。蓄勢、破甲與第二屬性攻擊都需要配置到招式欄。換人占一回合；每場最多用2次戰鬥補給，多波首領不會重置次數。"],["捕捉與圖鑑","四級靈晶都能嘗試捕捉一般精靈。先降低血量或施加異常狀態；按鈕會顯示成功率。首次取得新路線有金幣與材料，圖鑑未取得的形態顯示灰色；從「更多 → 領任務與收集獎勵」領取里程碑。傳說精靈有自己的棲地與試煉。"],["補血與培養","點右側任何一隻精靈可直接補血、裝備與分配潛力。城鎮治療所要付金幣；帳篷與野營包會消耗道具，不能無限免費補滿。每隻精靈有不同天生資質，可用天賦重塑露重洗並先比較新舊；升級可得成長點，特訓券可練熟練度。裝備分R／SR／SSR／UR。"],["孵蛋與抽獎","更多 → 孵蛋／精靈配對：選擇雙親圖片後，用材料送入育成所80步，暫時不能上場；接回雙親領蛋後，再探索160步孵化。冒險抽獎只用遊戲裡取得的券，公開機率，每10抽內保證稀有獎勵。蛋滿了會暫存，不會消失。"],["舊存檔與等級","可保留舊版精靈、道具與收藏；新版12篇冒險另外記錄進度。高等精靈在低等區域保留原本等級與形態，培育成果不會被壓低。"],["與朋友連線、存檔","Windows版可建立最多2人的房間，朋友用主機IP加入。跨網路需可連到TCP 8877或共同VPN，本版沒有公開中繼。F5儲存，F9讀取；戰鬥中不能存檔。網頁版可加入房間，不能建立主機。"]]:
  campaign_ui.row(v,card[0],card[1])
 v.add_child(button("返回遊戲",close_overlay,Vector2(400,44)))
func show_type_guide():combat_ui.type_chart()
func _new_overlay(kind,title,rect=Rect2(70,96,820,530)):
 if modal_kind=="codex" and is_instance_valid(codex_scroll):codex_scroll_value=codex_scroll.scroll_vertical
 if not navigating_back and kind!=modal_kind and not modal_kind in ["","start","battle","battle_result"] and not kind in ["start","battle","battle_result"]:ui_history.append(current_route.duplicate(true))
 current_route={"kind":kind,"uid":adventure_ui.selected_uid if adventure_ui else "","chapter":adventure_ui.chapter_selected if adventure_ui else 1,"plan_area":current_route.get("plan_area",""),"quest_area":current_route.get("quest_area",""),"family":current_route.get("family",""),"item":item_ui.selected if item_ui else ""}
 if overlay:
  remove_child(overlay);overlay.queue_free()
 if kind!="battle":battle_widgets={}
 modal_kind=kind;path=[];interact_target=""
 if mobile:mobile.direction=Vector2i.ZERO
 var section={"item_detail":"inventory","codex_detail":"codex","chapter_map":"world_map","quick":"training","adventure":"rewards"}.get(kind,kind)
 for nav in get_tree().get_nodes_in_group("main_navigation"):
  if nav.get_meta("section","")==section:nav.add_theme_stylebox_override("normal",skin.style("button-hover",8))
  else:nav.remove_theme_stylebox_override("normal")
 overlay=Control.new();overlay.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR;overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(overlay)
 var shade=ColorRect.new();shade.color=Color(0.018,0.027,0.052,0.86);shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);overlay.add_child(shade)
 var panel=_panel(rect);overlay.add_child(panel)
 var v=VBoxContainer.new();v.add_theme_constant_override("separation",10);panel.add_child(v)
 var head=HBoxContainer.new();v.add_child(head)
 var name_label=label(title,23,Color("f1d394"));name_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;head.add_child(name_label)
 if not kind in ["start","battle"] and not ui_history.is_empty():head.add_child(button("返回上一頁",navigate_back,Vector2(130,32)))
 if not kind in ["start","battle"]:head.add_child(button("關閉",close_overlay,Vector2(70,32)))
 for presentation in get_tree().get_nodes_in_group("presentations"):
  if presentation.get_parent()==self:move_child(presentation,get_child_count()-1)
 if audio:audio.set_context(music_context())
 _web_sync.call_deferred()
 return v
func close_overlay():
 if party_ui and modal_kind=="party":party_ui.swap_uid="";party_ui.swap_slot=-1;party_ui.move_slot=-1;party_ui.gear_slot=""
 if not player().is_empty() and not player().get("battle","").is_empty() and snapshot.get("battles",{}).has(player().battle):
  show_battle();return
 if overlay:
  remove_child(overlay);overlay.queue_free();overlay=null
 modal_kind="";battle_widgets={};battle_seen="";ui_history=[]
 if audio:audio.set_context(music_context())
 _web_sync.call_deferred()
 if is_instance_valid(battle_intro):battle_intro.skip()
func _wrap(text,size=16,color=Color("e9efe5")):
 var l=label(text,size,color);l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;l.size_flags_horizontal=Control.SIZE_EXPAND_FILL;return l
func art(mon,minsize=Vector2(200,180),_concept=false):
 var picture=TextureRect.new();picture.texture=visuals.sprite_texture(mon);picture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;picture.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;picture.custom_minimum_size=minsize;picture.size_flags_horizontal=Control.SIZE_SHRINK_CENTER;picture.size_flags_vertical=Control.SIZE_SHRINK_CENTER;return picture
func show_start():
 var v=_new_overlay("start","靈嶼：共鳴遠征",Rect2(110,95,1060,610))
 v.add_child(_wrap("十二篇冒險 v0.9.2 · 100條路線／244形態／研究與孵蛋／雙人直連\n選擇你的第一位夥伴，調查穗風原失去的風聲。",16))
 var row=HBoxContainer.new();row.size_flags_vertical=Control.SIZE_EXPAND_FILL;row.add_theme_constant_override("separation",12);v.add_child(row)
 for id in rules.data.STARTERS:
  var col=VBoxContainer.new();col.size_flags_horizontal=Control.SIZE_EXPAND_FILL;col.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(col)
  col.add_child(art({"family":id,"stage":1},Vector2(260,260)))
  col.add_child(label(rules.data.family(id).forms[0].name_zh,22,Color("d8dfb0")))
  col.add_child(_type_row(rules.data.family(id).types,23));col.add_child(_wrap(rules.data.family(id).role,13))
  col.add_child(button("選擇這位夥伴",_choose.bind(id),Vector2(240,44)))
 var bottom=HBoxContainer.new();v.add_child(bottom)
 if _save_exists():bottom.add_child(button("繼續上次冒險",load_game,Vector2(240,42)))
 bottom.add_child(button("操作與連線說明",show_help,Vector2(240,42)))
func _choose(id):
 close_overlay();_send_command({"kind":"choose","family":id});show_tutorial()
func show_help():show_tutorial()
func show_party():party_ui.open()
func _selected_mon():
 var p=player()
 for group in ["party","bench"]:
  for i in range(p[group].size()):
   if p[group][i].uid==party_selected_uid:return {"mon":p[group][i],"group":group,"index":i}
 if party_target_slot<p.party.size():
  party_selected_uid=p.party[party_target_slot].uid
  return {"mon":p.party[party_target_slot],"group":"party","index":party_target_slot}
 return {}
func _select_party_slot(index):
 if index<0 or index>=player().party.size():return
 party_target_slot=index;party_ui.select_mon(player().party[index].uid)
func _inspect_mon(uid):party_ui.select_mon(uid)
func _bench_swap(uid):
 party_selected_uid=uid;party_confirm={};_send_command({"kind":"storage","uid":uid,"slot":party_target_slot})
func _confirm_mon_action(method):
 var selected=_selected_mon()
 if selected.is_empty():return
 party_confirm={"method":method,"uid":selected.mon.uid,"group":selected.group};party_ui.section="evolution" if method=="evolve" else "manage";show_party()
func _cancel_mon_action():party_confirm={};show_party()
func _commit_mon_action():
 if party_confirm.is_empty():return
 var selected=_selected_mon()
 if selected.is_empty() or selected.mon.uid!=party_confirm.uid:party_confirm={};show_party();return
 var method=party_confirm.method;party_confirm={}
 if method=="evolve":_send_command({"kind":"evolve","index":selected.index})
 else:_send_command({"kind":"dispose","uid":selected.mon.uid,"group":selected.group,"method":method})
func _party_detail(index):
 if index>=0 and index<player().party.size():_inspect_mon(player().party[index].uid)
func show_bag():adventure_ui.inventory()
func show_shop():campaign_ui.shop()
func show_quests():journal_ui.open("main")
func show_services():adventure_ui.more()
func _track_quest(id):
 if id!="main" and not id.begins_with("side_") and not rules.data.adventure.commissions.any(func(q):return q.id==id):return
 tracked_quest=id;sidebar_key="";close_overlay();_refresh();show_notice("正在追蹤",rules.data.quest_guide(snapshot.world,player(),tracked_quest).title)
func show_codex():
 var p=player();var v=_new_overlay("codex","圖鑑 · 用圖片找到你的精靈",Rect2(70,65,1140,675))
 var filters=HBoxContainer.new();v.add_child(filters)
 var search=LineEdit.new();search.placeholder_text="搜尋名字、進化名、編號或屬性";search.text=codex_query;search.custom_minimum_size=Vector2(340,37);filters.add_child(search)
 search.text_changed.connect(func(text):codex_query=text;_reset_codex_view())
 var option=OptionButton.new();option.custom_minimum_size=Vector2(170,37);option.add_item("全部狀態");option.add_item("已觀察");option.add_item("已收集");option.select(["all","seen","caught"].find(codex_filter));filters.add_child(option)
 option.item_selected.connect(func(index):codex_filter=["all","seen","caught"][index];_reset_codex_view())
 var type_option=OptionButton.new();type_option.expand_icon=true;type_option.add_theme_constant_override("icon_max_width",20);type_option.get_popup().add_theme_constant_override("icon_max_width",20);type_option.custom_minimum_size=Vector2(160,37);type_option.add_item("全部屬性")
 var type_keys=rules.data.ADVANTAGE.keys()
 for type in type_keys:type_option.add_icon_item(visuals.icon(type),type)
 type_option.select(0 if codex_type.is_empty() else type_keys.find(codex_type)+1);filters.add_child(type_option)
 type_option.item_selected.connect(func(index):codex_type="" if index==0 else type_keys[index-1];_reset_codex_view())
 filters.add_child(button("屬性圖示說明",show_type_guide,Vector2(180,37)))
 var categories=HBoxContainer.new();v.add_child(categories)
 var sources=[["all","全部取得方式"],["wild","野外捕捉"],["egg","孵蛋／培育"],["fossil","化石復原"],["starter","初始夥伴"],["quest","任務贈送"],["shrine","傳說棲地試煉"]]
 var source=OptionButton.new();source.custom_minimum_size=Vector2(250,37)
 for pair in sources:source.add_item(pair[1])
 source.select(sources.map(func(pair):return pair[0]).find(codex_source));source.item_selected.connect(func(index):codex_source=sources[index][0];_reset_codex_view());categories.add_child(source)
 var kinds=[["all","全部精靈類別"],["normal","一般精靈"],["boss","章節首領"],["guardian","守域獸"],["legend","傳說／幻獸"]]
 var category=OptionButton.new();category.custom_minimum_size=Vector2(250,37)
 for pair in kinds:category.add_item(pair[1])
 category.select(kinds.map(func(pair):return pair[0]).find(codex_category));category.item_selected.connect(func(index):codex_category=kinds[index][0];_reset_codex_view());categories.add_child(category)
 var stages=OptionButton.new();stages.custom_minimum_size=Vector2(220,37)
 for title in ["全部進化路線","不進化","二階段","三階段"]:stages.add_item(title)
 stages.select(codex_stages);stages.item_selected.connect(func(index):codex_stages=index;_reset_codex_view());categories.add_child(stages)
 var region=OptionButton.new();region.custom_minimum_size=Vector2(270,37);region.add_item("全部出沒地區")
 for c in rules.data.adventure.chapters:region.add_item("第%d篇 · %s" % [c.id,c.title])
 region.select(codex_region);region.item_selected.connect(func(index):codex_region=index;_reset_codex_view());categories.add_child(region)
 codex_count_label=label("",13,Color("bfd6bc"));v.add_child(codex_count_label)
 var scroll=ScrollContainer.new();codex_scroll=scroll;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;v.add_child(scroll)
 codex_grid=GridContainer.new();codex_grid.columns=4;codex_grid.add_theme_constant_override("h_separation",12);codex_grid.add_theme_constant_override("v_separation",12);scroll.add_child(codex_grid)
 _fill_codex_grid()
 _restore_codex.call_deferred(scroll,codex_scroll_value)
func _fill_codex_grid():
 if not is_instance_valid(codex_grid):return
 for child in codex_grid.get_children():codex_grid.remove_child(child);child.queue_free()
 var p=player()
 for id in rules.data.IDS:
  var f=rules.data.family(id)
  var sources=codex_sources(id)
  if codex_source!="all" and not codex_source in sources:continue
  if codex_category=="normal" and f.category!="一般":continue
  if codex_category=="guardian" and f.category!="守域獸":continue
  if codex_category=="legend" and not f.category in ["傳說","幻獸"]:continue
  if codex_category=="boss" and not rules.data.adventure.chapters.any(func(c):return c.boss==id):continue
  if codex_stages>0 and int(f.stage_count)!=codex_stages:continue
  if codex_region>0 and not id in rules.data.adventure.chapters[codex_region-1].pool:continue
  if not codex_query.is_empty() and not (id+f.route+"／".join(f.types)).to_lower().contains(codex_query.to_lower()):continue
  if codex_filter=="seen" and not id in p.seen:continue
  if codex_filter=="caught" and not id in p.dex:continue
  if not codex_type.is_empty() and not codex_type in f.types:continue
  var card=PanelContainer.new();card.custom_minimum_size=Vector2(260,238);card.add_theme_stylebox_override("panel",box(Color("21433f"),Color("90aa78") if id in p.dex else Color("496c62")));codex_grid.add_child(card)
  var col=VBoxContainer.new();card.add_child(col)
  col.add_child(label(id+"  ·  "+("已收集" if id in p.dex else ("已觀察" if id in p.seen else "尚未遇見")),12,Color("b2c6a6")))
  var picture=art({"family":id,"stage":1},Vector2(220,118));picture.size_flags_vertical=Control.SIZE_SHRINK_CENTER;gray_if_unknown(picture,id+":1");picture.mouse_filter=Control.MOUSE_FILTER_STOP;picture.gui_input.connect(func(e):
   if e is InputEventMouseButton and e.pressed and e.button_index==MOUSE_BUTTON_LEFT:_codex_detail(id));col.add_child(picture)
  col.add_child(_type_row(f.types,20));col.add_child(label(f.category+" · "+("三階段" if f.stage_count==3 else "二階段" if f.stage_count==2 else "不進化"),12));col.add_child(button(f.forms[0].name_zh+" · 查看進化",_codex_detail.bind(id),Vector2(225,35)))
 if is_instance_valid(codex_count_label):codex_count_label.text="找到 %d 條路線 · 已收集 %d／100。篩選可交叉使用，返回會保留目前位置。" % [codex_grid.get_child_count(),p.dex.size()]
 if codex_grid.get_child_count()==0:codex_grid.add_child(label("沒有符合的角色，請調整搜尋或篩選。",17))
func _codex_detail(id):
 var f=rules.data.family(id);var v=campaign_ui._page("codex_detail",f.route);current_route["family"]=id
 v.add_child(_type_row(f.types,30))
 var row=HBoxContainer.new();row.size_flags_vertical=Control.SIZE_EXPAND_FILL;row.add_theme_constant_override("separation",38);v.add_child(row)
 for i in range(f.stage_count):
  var col=VBoxContainer.new();col.size_flags_horizontal=Control.SIZE_EXPAND_FILL;col.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(col)
  var picture=art({"family":id,"stage":i+1},Vector2(210,155));gray_if_unknown(picture,id+":"+str(i+1));col.add_child(picture)
  col.add_child(label(f.forms[i].name_zh,21,Color("ead5a5")))
  col.add_child(_wrap("第一階" if i==0 else "第%d階" % (i+1),13))
  if i<f.stage_count-1:col.add_child(_wrap("進化條件："+str(f.forms[i].evolution_condition),15,Color("c2dbb3")))
 v.add_child(_wrap(f.ecology+"\n取得方式："+f.acquisition,14))
 v.add_child(button("返回圖鑑（保留位置）",_return_codex))
func show_battle():
 var p=player();var b=snapshot.battles.get(p.battle,{})
 if b.is_empty():return
 if modal_kind=="battle" and is_instance_valid(battle_widgets.get("stage")) and battle_widgets.get("id","")==b.id:
  _update_battle(b);return
 var first_entry=battle_seen!=b.id;battle_seen=b.id
 var v=_new_overlay("battle","首領安撫戰" if b.boss else "野外遭遇",Rect2(45,68,1190,674))
 battle_widgets={"id":b.id,"snapshot":b,"buttons":{},"display_hp":{},"result":false,"previous_level":p.party[p.active].level,"previous_xp":p.party[p.active].xp,"mon_uid":p.party[p.active].uid}
 var header=HBoxContainer.new();header.add_theme_constant_override("separation",22);v.add_child(header)
 var left=VBoxContainer.new();left.size_flags_horizontal=Control.SIZE_EXPAND_FILL;header.add_child(left)
 battle_widgets["player_name"]=label("",19,Color("e9dfb6"));left.add_child(battle_widgets.player_name)
 battle_widgets["player_types"]=_type_row(rules.data.family(p.party[p.active].family).types,20);left.add_child(battle_widgets.player_types)
 battle_widgets["player_hp_text"]=label("",12);left.add_child(battle_widgets.player_hp_text)
 battle_widgets["player_hp"]=_meter(p.party[p.active].hp,rules.max_hp(p.party[p.active]),Color("92c99b"),10);left.add_child(battle_widgets.player_hp)
 battle_widgets["xp"]=_meter(p.party[p.active].xp,rules.xp_to_next(int(p.party[p.active].level)),Color("8fb9ed"),5);left.add_child(battle_widgets.xp)
 battle_widgets["xp_text"]=label("",11,Color("a9c8e7"));left.add_child(battle_widgets.xp_text)
 var middle=VBoxContainer.new();middle.custom_minimum_size.x=230;header.add_child(middle)
 battle_widgets["round"]=label("",21,Color("f6d889"));middle.add_child(battle_widgets.round)
 battle_widgets["resonance_text"]=label("",13);middle.add_child(battle_widgets.resonance_text)
 battle_widgets["resonance"]=_meter(snapshot.world.resonance,100,Color("e7b8da"),8);middle.add_child(battle_widgets.resonance)
 var speed=button(_speed_text(),cycle_speed,Vector2(70,28));speed.add_to_group("speed_controls");middle.add_child(speed)
 var right=VBoxContainer.new();right.size_flags_horizontal=Control.SIZE_EXPAND_FILL;header.add_child(right)
 battle_widgets["enemy_name"]=label("",19,Color("f0d1af"));right.add_child(battle_widgets.enemy_name)
 right.add_child(_type_row(rules.data.family(b.enemy.family).types,20))
 battle_widgets["enemy_hp_text"]=label("",12);right.add_child(battle_widgets.enemy_hp_text)
 battle_widgets["enemy_hp"]=_meter(b.enemy.hp,b.enemy_max,Color("e5a07e"),10);right.add_child(battle_widgets.enemy_hp)
 var stage=BattleStage.new();stage.main=self;stage.custom_minimum_size=Vector2(1140,200);stage.size_flags_vertical=Control.SIZE_EXPAND_FILL;v.add_child(stage);battle_widgets["stage"]=stage
 stage.impact.connect(_battle_impact.bind(stage));stage.presentation_finished.connect(_presentation_done.bind(stage))
 var log_label=label("",13);log_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;log_label.custom_minimum_size.y=42;v.add_child(log_label);battle_widgets["log"]=log_label
 var grid=GridContainer.new();grid.columns=4;grid.add_theme_constant_override("h_separation",8);grid.add_theme_constant_override("v_separation",7);v.add_child(grid)
 for i in range(4):
  var move_button=button("招式%d" % (i+1),_send_command.bind({"kind":"battle","action":"move","index":i}),Vector2(270,66));move_button.add_theme_font_size_override("font_size",15);grid.add_child(move_button);battle_widgets.buttons["move"+str(i)]=move_button
 for pair in [["守勢 · 回2能量","guard"],["更換精靈","switch"],["背包道具","help"],["屬性克制表（T）","types"],["草本藥","potion"],["靈晶","catch"],["共鳴連攜","resonance"],["逃跑","flee"]]:
  var callback=show_battle_switch if pair[1]=="switch" else show_tactics if pair[1]=="help" else show_type_guide if pair[1]=="types" else _send_command.bind({"kind":"battle","action":pair[1]})
  var bttn=button(pair[0],callback,Vector2(270,46));bttn.add_theme_font_size_override("font_size",15)
  var action_icons={"guard":25,"switch":21,"help":39,"types":30,"resonance":27,"flee":31}
  bttn.icon=skin.item_texture("potion",rules.data.campaign.items.potion) if pair[1]=="potion" else skin.item_texture("seal",rules.data.campaign.items.seal) if pair[1]=="catch" else skin.indexed(action_icons.get(pair[1],31));bttn.expand_icon=true;bttn.add_theme_constant_override("icon_max_width",32)
  grid.add_child(bttn);battle_widgets.buttons[pair[1]]=bttn
 battle_widgets["continue"]=button("繼續冒險",_continue_after_battle,Vector2(300,43));battle_widgets["continue"].visible=false;v.add_child(battle_widgets["continue"])
 if not first_entry:stage.last_serial=int(b.get("event_serial",0))
 _update_battle(b,true)
 if first_entry:
  audio.play("encounter")
  battle_intro=BattleIntro.new();battle_intro.main=self;battle_intro.battle=b;battle_intro.player_mon=p.party[p.active].duplicate(true);add_child(battle_intro)
  battle_intro.finished.connect(func():battle_intro=null;_battle_buttons();_web_sync())
func _update_battle(b,initial=false):
 if battle_widgets.is_empty() or not is_instance_valid(battle_widgets.get("stage")):return
 var p=player();var m=p.party[p.active];var stage=battle_widgets.stage
 if battle_widgets.mon_uid!=m.uid:
  battle_widgets.mon_uid=m.uid;battle_widgets.previous_level=m.level;battle_widgets.previous_xp=m.xp
  var type_row=battle_widgets.player_types;var parent=type_row.get_parent();var index=type_row.get_index();parent.remove_child(type_row);type_row.queue_free()
  type_row=_type_row(rules.data.family(m.family).types,20);parent.add_child(type_row);parent.move_child(type_row,index);battle_widgets.player_types=type_row
  battle_widgets.player_hp.max_value=rules.max_hp(m);battle_widgets.player_hp.value=m.hp;_update_hp_texts();_set_xp(m,false)
 battle_widgets.snapshot=b
 if initial or not stage.busy():
  battle_widgets.player_name.text="%s  Lv.%d%s" % [rules.data.mon_name(m),m.level,"（本場同步%d）" % int(m.sync_level) if m.has("sync_level") else ""]
  battle_widgets.enemy_name.text="%s  Lv.%d %s" % [rules.data.mon_name(b.enemy),b.enemy.level,b.enemy.status]
 battle_widgets.round.text=("收服成功" if b.get("result","")=="caught" else "戰鬥勝利") if battle_widgets.result else "第%d回合" % b.round
 battle_widgets.resonance_text.text="共鳴 %d%% · %d位玩家" % [snapshot.world.resonance,b.participants.size()]
 battle_widgets.resonance.value=snapshot.world.resonance
 battle_widgets.log.text="\n".join(b.log.slice(maxi(0,b.log.size()-3)))
 if initial:
  battle_widgets.display_hp={local_id:m.hp,"enemy":b.enemy.hp}
  battle_widgets.player_hp.max_value=rules.max_hp(m);battle_widgets.player_hp.value=m.hp
  battle_widgets.enemy_hp.max_value=b.enemy_max;battle_widgets.enemy_hp.value=b.enemy.hp
  _update_hp_texts()
  _set_xp(m,false)
 stage.configure(b,p,snapshot,true)
 _battle_buttons()
func _battle_buttons():combat_ui.update_buttons()
func _update_hp_texts():
 if battle_widgets.is_empty():return
 battle_widgets.player_hp_text.text="生命 %d／%d　氣力 %d／12" % [int(battle_widgets.player_hp.value),int(battle_widgets.player_hp.max_value),player().party[player().active].pp]
 battle_widgets.enemy_hp_text.text="生命 %d／%d" % [int(battle_widgets.enemy_hp.value),int(battle_widgets.enemy_hp.max_value)]
func _battle_impact(event,stage):
 if battle_widgets.get("stage")!=stage:return
 if audio:audio.play(event.kind if event.kind in ["faint","send_out"] else "heal" if event.kind=="heal" else "catch" if event.kind=="catch" else "hit" if event.actor=="enemy" else "attack",1.15 if event.type in ["風","雷"] else 1.0)
 var target=str(event.target)
 var bar=battle_widgets.enemy_hp if target=="enemy" else (battle_widgets.player_hp if target==local_id else null)
 if bar!=null and int(event.amount)>0:
  var new_value=clampf(bar.value+(event.amount if event.kind=="heal" else -event.amount),0,bar.max_value)
  var tween=create_tween();tween.tween_property(bar,"value",new_value,.22);tween.tween_callback(_update_hp_texts)
func _presentation_done(stage):
 combat_ui.offer_replacement.call_deferred()
 if battle_widgets.get("stage")!=stage:return
 var b=battle_widgets.snapshot;var m=player().party[player().active]
 battle_widgets.player_hp.max_value=rules.max_hp(m)
 create_tween().tween_property(battle_widgets.player_hp,"value",m.hp,.18).finished.connect(_update_hp_texts)
 create_tween().tween_property(battle_widgets.enemy_hp,"value",b.enemy.hp,.18).finished.connect(_update_hp_texts)
 battle_widgets.player_name.text="%s  Lv.%d%s" % [rules.data.mon_name(m),m.level,"（本場同步%d）" % int(m.sync_level) if m.has("sync_level") else ""]
 if battle_widgets.result:
  battle_widgets.log.text=("收服成功" if b.result=="caught" else "戰鬥勝利")+"！獲得 %d 經驗、%d 金幣。\n" % [b.xp_reward,b.coin_reward]+player().message.get_slice("\n",0)
  _set_xp(m,true)
 _battle_buttons()
func _set_xp(m,animate):
 if not battle_widgets.has("xp"):return
 var bar=battle_widgets.xp;var text=battle_widgets.xp_text
 var old_level=int(battle_widgets.get("previous_level",m.level));var old_xp=int(battle_widgets.get("previous_xp",m.xp))
 if not animate:
  bar.max_value=1 if m.level>=current_cap() else rules.xp_to_next(int(m.level));bar.value=1 if m.level>=current_cap() else m.xp
 else:
  bar.max_value=rules.xp_to_next(old_level);bar.value=old_xp;var tween=bar.create_tween()
  for level in range(old_level,int(m.level)):
   tween.tween_property(bar,"value",rules.xp_to_next(level),.24)
   tween.tween_callback(func():bar.max_value=rules.xp_to_next(level+1);bar.value=0)
  tween.tween_property(bar,"value",1 if m.level>=current_cap() else m.xp,.32)
  if m.level>=current_cap():tween.tween_callback(func():bar.max_value=1;bar.value=1)
 text.text="已達最高等級" if m.level>=current_cap() else "經驗 %d／%d（還需%d）" % [m.xp,rules.xp_to_next(int(m.level)),rules.xp_to_next(int(m.level))-int(m.xp)]
 if animate and int(m.level)>old_level:text.text="升級！Lv.%d → Lv.%d　" % [old_level,m.level]+text.text
 battle_widgets.previous_level=m.level;battle_widgets.previous_xp=m.xp
func show_battle_result():
 var p=player();var summary=p.get("last_battle",{})
 if summary.is_empty():close_overlay();return
 if not is_instance_valid(battle_widgets.get("stage")):
  var v=_new_overlay("battle_result","戰鬥結算",Rect2(180,150,920,500));v.add_child(label("%s · %d經驗／%d金幣" % ["收服成功" if summary.result=="caught" else "戰鬥勝利",summary.xp_reward,summary.coin_reward],23))
  for mon in p.party:
   var row=HBoxContainer.new();v.add_child(row);row.add_child(art(mon,Vector2(55,55)));var col=VBoxContainer.new();col.size_flags_horizontal=Control.SIZE_EXPAND_FILL;col.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(col);col.add_child(label(rules.data.mon_name(mon)+" Lv."+str(int(mon.level)),16));col.add_child(_meter(mon.xp,rules.xp_to_next(int(mon.level)),Color("87b8ed"),9));col.add_child(label("經驗 %d／%d" % [mon.xp,rules.xp_to_next(int(mon.level))],12))
  v.add_child(button("繼續冒險",close_overlay));return
 if summary.id!=battle_widgets.get("id",""):close_overlay();return
 modal_kind="battle_result";battle_widgets.result=true
 if audio:audio.play("victory")
 if is_instance_valid(battle_intro):battle_intro.skip()
 _update_battle(summary)
 if not battle_widgets.stage.busy():_presentation_done(battle_widgets.stage)
func _continue_after_battle():
 if is_instance_valid(battle_widgets.get("stage")) and battle_widgets.stage.busy():return
 close_overlay()
func show_battle_switch():combat_ui.switch_picker()
func show_restart():
 var v=_new_overlay("restart","開始新的冒險？",Rect2(240,200,800,310))
 v.add_child(_wrap("將回到初始夥伴選擇，並離開或關閉目前房間。已儲存的舊進度仍會保留，直到你下次存檔覆寫。",17))
 v.add_child(button("確認重新開始",_restart))
 v.add_child(button("繼續目前冒險",close_overlay))
func _restart():
 multiplayer.multiplayer_peer=OfflineMultiplayerPeer.new();mode="solo";local_id="1";rules.reset();rules.add_player(1)
 snapshot=rules.room.duplicate(true);network_message="單人探索";last_save_message="";path=[]
 if overlay:remove_child(overlay);overlay.queue_free();overlay=null
 modal_kind="";_refresh();show_start()
func show_network():
 if mode!="solo":
  var v=_new_overlay("network","目前的連線",Rect2(220,130,820,490))
  v.add_child(_wrap(network_message+"\n\n主機TCP連接埠：8877。沒有公共中繼；跨網路需可到達的主機或共同VPN。\n離開時保留自己的精靈與共同世界進度，回到單人探索。",17))
  if mode=="host":
   var addresses=[]
   for ip in IP.get_local_addresses():
    if ":" not in ip and not ip.begins_with("127.") and ip!="0.0.0.0":addresses.append("ws://"+ip+":8877")
   v.add_child(_wrap("房主位址（朋友需在同網路或VPN）：\n"+"\n".join(addresses.slice(0,3)),15))
  v.add_child(button("與朋友交易精靈／道具",trade_ui.open));v.add_child(button("離開房間並保留進度",disconnect_room));return
 var v=_new_overlay("network","與朋友同行",Rect2(190,130,900,480))
 v.add_child(_wrap("Windows／Mac／Linux版可建立雙人主機；瀏覽器版只能加入。\n加入格式：ws://主機IP:8877。不同網路需要主機可被連到，或使用共同VPN。此版不提供免設定房碼與公開中繼。",16))
 var addr=LineEdit.new();addr.placeholder_text="ws://192.168.1.10:8877";addr.text="";addr.custom_minimum_size.y=45;v.add_child(addr)
 v.add_child(button("加入房間",_join_address.bind(addr),Vector2(300,45)))
 var host=button("建立雙人房間（TCP 8877）",_start_host.bind(false),Vector2(300,45));host.disabled=OS.has_feature("web");v.add_child(host)
 v.add_child(_wrap("合作以房主世界為準。各自保留隊伍、背包與任務獎勵紀錄。可以一起探索；靠近朋友可在戰鬥首輪加入。精靈與道具可在朋友交易頁交換。",14))
func _join_address(addr):join_room(addr.text)
func _start_host(server_only=false):
 var peer=WebSocketMultiplayerPeer.new();var error=peer.create_server(8877)
 if error!=OK:
  if not dedicated:player().message="無法建立主機：連接埠8877可能已被占用。";close_overlay();_refresh()
  else:push_error("Server start failed: "+str(error));get_tree().quit(1)
  return
 multiplayer.multiplayer_peer=peer;mode="server" if server_only else "host";local_id="1"
 network_message="主機已開啟 · TCP 8877 · 最多2位玩家"
 if server_only:print("SPIRIT_SERVER_READY 8877")
 else:close_overlay();_publish()
func join_room(address):
 if mode!="solo":return
 address=address.strip_edges()
 if mobile and mobile.enabled and address.begins_with("ws://") and str(JavaScriptBridge.eval("location.protocol"))=="https:":
  player().message="目前是HTTPS手機網站，需要wss://安全連線。房主可使用Tailscale Serve建立安全位址，詳見手機版連線說明。";close_overlay();_refresh();return
 if not (address.begins_with("ws://") or address.begins_with("wss://")):
  player().message="請使用 ws://主機IP:8877 或有效的 wss://網址。";close_overlay();_refresh();return
 pending_profile=rules.profile_of(local_id)
 var peer=WebSocketMultiplayerPeer.new();var error=peer.create_client(address)
 if error!=OK:player().message="無法連線，請檢查網址。";close_overlay();_refresh();return
 multiplayer.multiplayer_peer=peer;mode="connecting";connection_timer=12.0;network_message="正在加入房間……";close_overlay();_refresh()
func _on_connected():
 request_serial=0;local_id=str(multiplayer.get_unique_id());mode="client";network_message="已加入同行房間 · 主機權威同步"
 _rpc_request.rpc_id(1,{"kind":"hello","profile":pending_profile})
func _on_peer_connected(id):
 if multiplayer.is_server():print("PEER_CONNECTED ",id)
func _on_peer_disconnected(id):
 if multiplayer.is_server():rules.remove_player(id);_publish()
func _on_connection_failed():
 _recover_solo("無法連線。請確認主機、TCP 8877、防火牆與跨網路路由。")
func _on_server_disconnected():
 _recover_solo("房主已離線。保留最後同步的隊伍與世界進度，回到單人模式。")
func disconnect_room():
 _recover_solo("已離開房間並保留目前進度。")
func _recover_solo(text):
 var p=player();var profile=pending_profile if p.is_empty() else _profile_from(p)
 var world=snapshot.get("world",rules.room.world).duplicate(true)
 multiplayer.multiplayer_peer=OfflineMultiplayerPeer.new();mode="solo";local_id="1";rules.reset();rules.room.world=world
 var loaded=rules.add_player(1,profile);rules.unsync_party(loaded);loaded.message=text
 network_message="單人探索";close_overlay();_publish()
func _profile_from(p):
 var out={}
 for k in ["uid","name","party","bench","coins","bag","dex","seen","rewards","steps","active","stats","resource_steps","puzzle_progress","weather","tower","repel_steps","eggs","form_dex","parked_party","draw_pity","cosmetics","mail","legend_wins","waypoints","visited_areas","outfit","outfits","test_modified","nursery_jobs"]:out[k]=p[k].duplicate(true) if p[k] is Array or p[k] is Dictionary else p[k]
 return out
@rpc("any_peer","call_remote","reliable")
func _rpc_request(cmd):
 if not multiplayer.is_server() or not cmd is Dictionary:return
 var sender=multiplayer.get_remote_sender_id();var key=str(sender)
 if cmd.get("kind","")=="hello":
  if rules.room.players.size()>=2 and not rules.room.players.has(key):multiplayer.multiplayer_peer.disconnect_peer(sender);return
  if not rules.room.players.has(key):
   var newcomer=rules.add_player(sender,cmd.get("profile",{}))
   if rules.room.players.has("1"):rules.place_near_teammate(newcomer,rules.room.players["1"])
  _publish();return
 if not rules.room.players.has(key):return
 var seq=int(cmd.get("_request",0))
 var last=int(rules.room.players[key].get("ack",0))
 if seq<=last or seq>last+16:
  _publish();return
 if cmd.get("kind","")=="move":
  var now=Time.get_ticks_msec()
  if now-int(last_move_times.get(key,0))<60:
   rules.room.players[key].ack=seq;_publish();return
  last_move_times[key]=now
 rules.act(key,cmd);rules.room.players[key].ack=seq;_publish()
@rpc("authority","call_remote","reliable")
func _rpc_state(state):
 if state is PackedByteArray:
  var raw=state.decompress_dynamic(16*1024*1024,FileAccess.COMPRESSION_GZIP)
  if raw.is_empty():return
  state=bytes_to_var(raw)
 if not state is Dictionary:return
 snapshot=state;rules.room=snapshot;rules.adventure.apply_mode_overrides();rules.roaming.apply(snapshot.world);_refresh()
func _send_command(cmd):
 last_save_message=""
 if modal_kind in ["party","bag"] and cmd.get("kind","") in ["evolve","dispose","storage","active","potion","craft","use_item","equip"]:
  feedback_pending=modal_kind;feedback_seq=request_serial+1
 if audio and cmd.get("kind","")=="interact":audio.play("interact")
 if cmd.get("kind","")=="battle" and modal_kind in ["battle_switch","tactics","quick"]:show_battle()
 if modal_kind=="battle_result" and cmd.get("kind","") in ["move","interact","adv_enter"]:close_overlay()
 if mode=="connecting":return
 if mode=="client":
  request_serial+=1;cmd["_request"]=request_serial
  if OS.has_feature("web"):JavaScriptBridge.eval("window.spiritLastRequest="+str(request_serial)+";")
  _rpc_request.rpc_id(1,cmd)
 else:rules.act(local_id,cmd);_publish()
func _publish():
 rules.adventure.apply_mode_overrides();rules.roaming.apply(rules.room.world)
 snapshot=rules.room.duplicate(true)
 if mode in ["host","server"]:
  var packed=var_to_bytes(snapshot).compress(FileAccess.COMPRESSION_GZIP)
  for peer_id in multiplayer.get_peers():
   if multiplayer.multiplayer_peer is WebSocketMultiplayerPeer and multiplayer.multiplayer_peer.get_peer(peer_id).get_ready_state()!=WebSocketPeer.STATE_OPEN:continue
   _rpc_state.rpc_id(peer_id,packed)
 if not dedicated:_refresh()
func save_game():
 var p=player()
 if p.is_empty() or not p.ready:return
 if not p.battle.is_empty():last_save_message="戰鬥中不能存檔，請先完成遭遇。";_refresh();return
 var save={"version":1,"saved_at":Time.get_unix_time_from_system(),"profile":_profile_from(p),"world":snapshot.world,"position":{"area":p.area,"x":p.x,"y":p.y}}
 var f=FileAccess.open(save_path,FileAccess.WRITE)
 if f==null:last_save_message="存檔失敗，請檢查瀏覽器儲存空間或檔案權限。"
 else:
  f.store_string(JSON.stringify(save));f.close()
  if OS.has_feature("web"):
   JavaScriptBridge.eval("try { localStorage.setItem("+JSON.stringify(web_save_key)+","+JSON.stringify(JSON.stringify(save))+"); } catch (error) {}",true)
   JavaScriptBridge.force_fs_sync()
  last_save_message="已儲存目前進度 ✓"
 _refresh()
func load_game():
 if mode!="solo":last_save_message="請先離開房間再讀取存檔。";_web_sync();return
 if not _save_exists():last_save_message="目前找不到存檔。";_web_sync();return
 var raw=FileAccess.get_file_as_string(save_path) if FileAccess.file_exists(save_path) else "{}"
 var save=JSON.parse_string(raw)
 if OS.has_feature("web"):
  var cached=JavaScriptBridge.get_interface("localStorage").getItem(web_save_key)
  if cached is String and not cached.is_empty():
   var candidate=JSON.parse_string(cached)
   if candidate is Dictionary and (not save is Dictionary or float(candidate.get("saved_at",0))>=float(save.get("saved_at",0))):save=candidate
 if not save is Dictionary or save.get("version",0)!=1:last_save_message="存檔格式不正確，未覆寫目前進度。";_refresh();return
 rules.reset();var p=rules.add_player(1,save.get("profile",{}))
 var saved_flags=save.get("world",{}).get("flags",{})
 for key in rules.room.world.flags:
  rules.room.world.flags[key]=bool(saved_flags.get(key,false))
 rules.room.world.resonance=clampi(int(save.get("world",{}).get("resonance",0)),0,100)
 rules.adventure.restore(save.get("world",{}).get("adventure",{}))
 var pos=save.get("position",{});var area=str(pos.get("area","village"));var x=int(pos.get("x",15));var y=int(pos.get("y",13))
 if area in rules.data.maps:
  p.area=area;p.x=x;p.y=y;rules.recover_position(p)
 rules.room.world["roaming"]=save.get("world",{}).get("roaming",{});rules.roaming.apply(rules.room.world)
 rules.travel.migrate(p)
 if not rules.ready_mon(p):rules.rescue(p)
 p.message="已讀取存檔。歡迎回到"+rules.data.maps[p.area].name+"。";close_overlay();last_save_message="";_publish()
func _process(delta):
 if mode in ["solo","host","server"] and rules.roaming and rules.roaming.tick(delta):_publish()
 if dedicated:return
 visual_time+=delta
 if pending_area_banner!="" and modal_kind=="":
  show_location_banner(pending_area_banner);pending_area_banner=""
 if mode=="connecting":
  connection_timer-=delta
  if connection_timer<=0:_on_connection_failed()
 var p=player()
 if p.is_empty():return
 if world_view:world_view.queue_redraw()
 move_clock-=delta
 if not p.ready and modal_kind=="":show_start();return
 if move_clock>0 or modal_kind!="" or is_instance_valid(evolution_presentation) or not p.ready or not p.battle.is_empty():return
 if mode=="client" and int(p.get("ack",0))<request_serial:return
 map_hub.tick_transport()
 if not interact_target.is_empty():
  var moving_target=rules.data.find_entity(p.area,interact_target)
  if moving_target.get("kind","")=="wild":
   if rules.distance(p,moving_target)<=1:
    var chased=interact_target;interact_target="";path=[];_send_command({"kind":"interact","id":chased});return
   if path.is_empty() or Vector2i(path[-1])!=Vector2i(moving_target.x,moving_target.y):navigate_to(Vector2i(moving_target.x,moving_target.y))
 var dir=mobile.direction if mobile and mobile.enabled else Vector2i.ZERO
 if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):dir=Vector2i.UP
 elif Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):dir=Vector2i.DOWN
 elif Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):dir=Vector2i.LEFT
 elif Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):dir=Vector2i.RIGHT
 if dir!=Vector2i.ZERO:path=[];interact_target="";map_hub.walking_to=""
 elif not path.is_empty():
  while not path.is_empty() and Vector2i(p.x,p.y)==Vector2i(path[0]):path.pop_front()
  if not path.is_empty():dir=Vector2i(path[0])-Vector2i(p.x,p.y)
 elif not interact_target.is_empty():
  var target=interact_target;interact_target="";_send_command({"kind":"interact","id":target});return
 if absi(dir.x)+absi(dir.y)==1:
  move_clock=.24 if p.get("crouching",false) else .13;_send_command({"kind":"move","dx":dir.x,"dy":dir.y})
func _unhandled_key_input(event):
 if not event.is_pressed() or event.is_echo():return
 if event.keycode==KEY_T:
  if modal_kind=="types":navigate_back() if not ui_history.is_empty() else close_overlay()
  else:show_type_guide()
  return
 if is_instance_valid(battle_intro) and event.keycode in [KEY_SPACE,KEY_ENTER,KEY_ESCAPE]:battle_intro.skip();return
 if modal_kind=="dialog" and event.keycode in [KEY_E,KEY_ENTER]:close_overlay();return
 if event.keycode==KEY_C and player().area.begins_with("a"):
  _send_command({"kind":"adventure_action","action":"crouch","value":0});return
 if event.keycode==KEY_TAB:cycle_speed();return
 if event.keycode==KEY_ESCAPE:
  if modal_kind not in ["start","battle"]:close_overlay()
 elif event.keycode==KEY_F5:save_game()
 elif event.keycode==KEY_F9:load_game()
 elif event.keycode in [KEY_E,KEY_ENTER] and modal_kind=="":
  var p=player();var nearest={};var best=2
  for e in rules.data.entities(p.area):
   var dist=rules.distance(p,e)
   if dist<best:nearest=e;best=dist
  if not nearest.is_empty():_send_command({"kind":"interact","id":nearest.id})
 _web_sync()
func _gui_input(event):
 if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT and modal_kind=="" and world_view:
  var tile=world_view.screen_to_tile(event.position)
  if tile.x<0:return
  var entity=world_view.entity_at_screen(event.position)
  navigate_to(Vector2i(entity.x,entity.y) if not entity.is_empty() else tile)
func navigate_to(tile,interact_after=true,keep_plan=false):
 if not keep_plan:map_hub.walking_to="";map_hub.walking_entity=""
 var p=player();var area=p.area
 if rules.data.blocked(area,tile.x,tile.y):return
 var grid=AStarGrid2D.new();grid.region=Rect2i(0,0,rules.data.maps[area].size[0],rules.data.maps[area].size[1]);grid.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_NEVER;grid.update()
 for y in range(grid.region.size.y):
  for x in range(grid.region.size.x):grid.set_point_solid(Vector2i(x,y),rules.data.blocked(area,x,y))
 for e in rules.data.entities(area):
  if e.kind=="route_portal" and Vector2i(e.x,e.y)!=tile and Vector2i(e.x,e.y)!=Vector2i(p.x,p.y):grid.set_point_solid(Vector2i(e.x,e.y),true)
 path=rules.adventure.route(p,tile) if rules.adventure.defn(p).get("mode","")=="survival" else Array(grid.get_id_path(Vector2i(p.x,p.y),tile));interact_target=""
 if path.is_empty() and Vector2i(int(p.x),int(p.y))!=tile:
  map_hub.walking_to="";map_hub.walking_entity="";map_hub.teleport_phase="";map_hub.teleport_to=""
  show_notice("目前無法走到目標", "路線被阻擋，請先查看本區地圖或重新選擇目的地。")
  return
 for e in rules.data.entities(area):
  if interact_after and e.x==tile.x and e.y==tile.y:interact_target=e.id;break
func _web_command(args):
 if args.size()==0:return
 var cmd=JSON.parse_string(str(args[0]))
 if not cmd is Dictionary:return
 if str(cmd.get("kind","")).begins_with("mobile_"):
  mobile.handle(cmd);_web_sync();return
 match cmd.get("kind",""):
  "menu":
   match cmd.get("name",""):
    "party":show_party()
    "quests":show_quests()
    "codex":show_codex()
    "item_detail":item_ui.show_detail()
    "tutorial","help":show_tutorial()
    "network":show_network()
    "switch":show_battle_switch()
    "types":show_type_guide()
    "world_map","chapter_map","adventure","quick","training","inventory","workshop","rewards","lottery","healing","more","options","legends","legend_shrine","local_map","outfits","tester","boss_rematch","boss_drops","lookup","place_info","trade":adventure_ui.show(cmd.name)
    "services","shop","craft","research","board","nursery","travel","collection","settings","challenges","tactics":campaign_ui.show(cmd.name)
    "close":close_overlay()
  "ui_snapshot":_web_ui_snapshot()
  "save":save_game()
  "load":load_game()
  "join":join_room(str(cmd.get("address","")))
  "choose":_choose(str(cmd.get("family","")))
  "back":navigate_back()
  "font":set_ui_font_size(int(cmd.get("size",16)))
  "quick":adventure_ui.quick(str(cmd.get("uid","")))
  "evolution_preview":evolution_ui.open(str(cmd.get("uid","")))
  "evolution_task":evolution_task_ui.open(str(cmd.get("family","R006")))
  "movebook":combat_ui.movebook(str(cmd.get("uid","")))
  "journal_tab":journal_ui.open(str(cmd.get("tab","main")))
  "speed":cycle_speed()
  "party_slot":_select_party_slot(int(cmd.get("index",0)))
  "inspect":_inspect_mon(str(cmd.get("uid","")))
  "bench_swap":_bench_swap(str(cmd.get("uid","")))
  "confirm_mon":_confirm_mon_action(str(cmd.get("method","")))
  "commit_mon":_commit_mon_action()
  "track":_track_quest(str(cmd.get("id","main")))
  "navigate_quest":focus_quest_target()
  _: _send_command(cmd)
 _web_sync()
func _web_sync():
 if not OS.has_feature("web"):return
 var status={"room":snapshot,"local_id":local_id,"mode":mode,"modal":modal_kind,"save_message":last_save_message,"speed":game_speed,"battle_intro":is_instance_valid(battle_intro),"party_feedback":party_feedback,"party_selection":party_selected_uid,"party_slot":party_target_slot,"tracked_quest":tracked_quest,"audio_context":audio.context if audio else "","music_playing":audio.music.playing if audio and audio.music else false,"music_volume":audio.music_volume if audio else 0,"font_size":ui_font_size,"selected_item":item_ui.selected,"inventory_page":adventure_ui.inventory_page,"history":ui_history,"route":current_route}
 JavaScriptBridge.eval("window.spiritState="+JSON.stringify(status)+";",true)

func unlocked_chapter():return mini(8,rules.adventure.unlocked())
func current_cap():return 70
func show_tactics():campaign_ui.tactics()
func _tactical_command(action):_send_command({"kind":"battle","action":action})
func _revive_command(index):_send_command({"kind":"battle","action":"revive","index":index})
func show_discovery(discovery):
 if mobile and mobile.enabled:mobile.notify("圖鑑首次登錄",discovery.message,"reward");return
 var card=_panel(Rect2(300,85,660,90));card.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(card)
 var row=HBoxContainer.new();row.mouse_filter=Control.MOUSE_FILTER_IGNORE;card.add_child(row);row.add_child(art({"family":discovery.family,"stage":1},Vector2(70,65)))
 var col=VBoxContainer.new();col.size_flags_horizontal=Control.SIZE_EXPAND_FILL;col.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(col);col.add_child(label("圖鑑首次登錄 · "+rules.data.family(discovery.family).forms[0].name_zh,20,Color("ffe0a0")));col.add_child(label(discovery.message,14));col.add_child(label("目前 %d／100 · 驛站研究員可領里程碑" % discovery.count,12))
 var tween=card.create_tween();tween.tween_interval(3.0);tween.tween_property(card,"modulate:a",0.0,.4);tween.tween_callback(card.queue_free)

func _save_exists():
 if FileAccess.file_exists(save_path):return true
 if OS.has_feature("web"):
  var cached=JavaScriptBridge.get_interface("localStorage").getItem(web_save_key)
  return cached is String and not cached.is_empty()
 return false

func plain_text(text):
 var replacements={"靈晶":"靈晶","捕捉球":"靈晶","巡嶼員":"冒險家","巡嶼徽記":"冒險徽章","共鳴粉":"精靈粉塵","氣力":"能量","驛站服務":"更多功能","驛站":"服務區","生態研究":"收集獎勵","寄放":"倉庫"}
 for word in replacements:text=text.replace(word,replacements[word])
 return text
func ui_size(size):return int(round(float(size)*clampf(float(ui_font_size)/16.0,.9,1.15))) if size<=12 else int(round(float(size)*float(ui_font_size)/16.0))
func _load_ui_settings():
 var cfg=ConfigFile.new()
 if cfg.load("user://ui.cfg")==OK:ui_font_size=clampi(int(cfg.get_value("ui","font_size",16)),14,20)
 if OS.has_feature("web"):
  var saved=JavaScriptBridge.get_interface("localStorage").getItem("spirit-isles-ui-font")
  if saved is String and saved.is_valid_int():ui_font_size=clampi(int(saved),14,20)
func set_ui_font_size(value):
 ui_font_size=clampi(int(value),14,20);var cfg=ConfigFile.new();cfg.set_value("ui","font_size",ui_font_size);cfg.save("user://ui.cfg")
 if OS.has_feature("web"):JavaScriptBridge.get_interface("localStorage").setItem("spirit-isles-ui-font",str(ui_font_size))
 if is_instance_valid(base_ui):remove_child(base_ui);base_ui.queue_free()
 sidebar_key="";ui_refresh_key="";_build_base_ui();move_child(base_ui,world_view.get_index()+1);_refresh();_web_sync()
func open_root(kind):
 ui_history=[];navigating_back=true
 match kind:
  "party":show_party()
  "codex":show_codex()
  "save":save_game()
  _:adventure_ui.show(kind)
 navigating_back=false
func navigate_back():
 if modal_kind=="party" and party_ui.swap_uid!="":party_ui.cancel_swap();return
 if ui_history.is_empty():close_overlay();return
 var route=ui_history.pop_back();navigating_back=true;item_ui.selected=route.get("item",item_ui.selected)
 var kind=route.get("kind","");adventure_ui.selected_uid=route.get("uid",adventure_ui.selected_uid);adventure_ui.chapter_selected=int(route.get("chapter",1))
 match kind:
  "party":show_party()
  "codex":show_codex()
  "codex_detail":_codex_detail(route.get("family","R001"))
  "item_detail":item_ui.show_detail()
  "battle_switch":show_battle_switch()
  "battle":show_battle()
  "area_plan":map_hub.destination(route.get("plan_area",player().area))
  "quest_detail":journal_ui.inspect_area(route.get("quest_area",player().area))
  "evolution_task":evolution_task_ui.open(route.get("family",evolution_task_ui.family))
  "evolution_route":evolution_ui.open(route.get("uid",evolution_ui.uid))
  "nursery_parent":nursery_ui.picker()
  "genes":genetics_ui.open(route.get("uid",genetics_ui.uid))
  "movebook":combat_ui.movebook(adventure_ui.selected_uid)
  "tutorial","help":show_tutorial()
  "network":show_network()
  "types":show_type_guide()
  "":close_overlay()
  _:
   if kind in ["shop","nursery","research","collection","challenges","dialog","survey"]:campaign_ui.show(kind)
   else:adventure_ui.show(kind)
 navigating_back=false;_web_sync()
func _sidebar_input(event,index):
 if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:_party_detail(index)
func gray_if_unknown(picture,key):
 if key in player().get("form_dex",[]):return
 if gray_shader==null:
  gray_shader=Shader.new();gray_shader.code="shader_type canvas_item; void fragment(){vec4 c=texture(TEXTURE,UV);float g=dot(c.rgb,vec3(.299,.587,.114));COLOR=vec4(vec3(g*.55),c.a*.85);}"
 var material=ShaderMaterial.new();material.shader=gray_shader;picture.material=material;picture.tooltip_text="尚未取得這個形態"
func music_context():
 var p=player()
 if p.is_empty() or not p.get("ready",false):return "v04/track_34"
 if not p.get("battle","").is_empty():
  var b=snapshot.battles.get(p.battle,{})
  if b.get("boss",false):return "v04/track_%02d" % (14 if int(b.get("wave",1))>=3 else 17 if int(b.get("wave",1))==2 else 7)
  return "v04/track_03"
 if modal_kind in ["world_map","chapter_map"]:return "v04/track_25"
 var map=rules.data.maps[p.area];var d=rules.adventure.defn(p)
 if not d.is_empty():
  var themes={"grid":[13,8,21],"stealth":[16,19,10],"dig":[37,40,15],"tide":[4,12,31],"detective":[27,1,2],"survival":[30,28,23],"tactics":[9,35,18],"raid":[17,28,29],"habitat":[13,16,20],"salvage":[38,39,5],"draft":[35,32,6],"time":[29,0,22],"memory":[2,13,25],"tracks":[20,9,16]}
  return "v04/track_%02d" % themes[d.mode][(int(d.index)+int(d.variant))%3]
 var n=rules.data.chapter_for(p.area)
 var town=[13,20,8,31,27,30,9,28][n-1];var field=[13,16,40,4,19,30,21,29][n-1]
 return "v04/track_%02d" % (town if map.get("zone","")=="town" else 37 if map.get("zone","")=="dungeon" else field)

func _reset_codex_view():
 codex_scroll_value=0
 if is_instance_valid(codex_scroll):codex_scroll.scroll_vertical=0
 _fill_codex_grid()
func _restore_codex(scroll,value):
 await get_tree().process_frame
 await get_tree().process_frame
 if is_instance_valid(scroll):scroll.scroll_vertical=value
func _return_codex():
 if not ui_history.is_empty() and ui_history[-1].get("kind","")=="codex":navigate_back()
 else:show_codex()
func codex_sources(id):
 var out=[];var f=rules.data.family(id)
 if f.category!="一般":return ["shrine"]
 out.append("egg")
 if id in rules.data.STARTERS:out.append("starter");out.append("quest")
 if id=="R006":out.append("quest")
 if id in ["R007","R008","R046","R047","R048"]:out.append("fossil")
 for area in rules.data.maps:
  if id in rules.data.maps[area].get("pool",[]):out.append("wild");break
 return out

func show_location_banner(area):
 if not rules.data.maps.has(area):return
 if mobile and mobile.enabled:mobile.notify(rules.data.maps[area].name,"已抵達新區域","area");return
 if is_instance_valid(location_banner):location_banner.queue_free()
 location_banner=preload("res://src/location_banner.gd").new();location_banner.setup(self,area);add_child(location_banner)

func _web_ui_snapshot():
 if not OS.has_feature("web"):return
 var result=[];var presentations=get_tree().get_nodes_in_group("presentations");var nodes=[presentations[-1]] if not presentations.is_empty() else [overlay] if is_instance_valid(overlay) else [base_ui]
 while not nodes.is_empty():
  var node=nodes.pop_back()
  if not is_instance_valid(node):continue
  for child in node.get_children():nodes.append(child)
  if node is Control and node.get_script()!=null and node.get_script().resource_path=="res://src/map_canvas.gd" and node.is_visible_in_tree():
   var map_rect=node.get_global_rect();result.append({"text":"map","kind":"MapCanvas","tooltip":"","disabled":false,"rect":[map_rect.position.x,map_rect.position.y,map_rect.size.x,map_rect.size.y],"options":[]})
  if node is SpinBox and node.is_visible_in_tree():
   var edit=node.get_line_edit();var input_rect=edit.get_global_rect();result.append({"text":edit.text,"secret":false,"kind":"LineEdit","tooltip":"numeric","disabled":not edit.editable,"rect":[input_rect.position.x,input_rect.position.y,input_rect.size.x,input_rect.size.y],"options":[]})
  if node is LineEdit and node.is_visible_in_tree():
   var input_rect=node.get_global_rect();result.append({"text":node.placeholder_text if node.secret else node.text,"secret":node.secret,"kind":"LineEdit","tooltip":"","disabled":not node.editable,"rect":[input_rect.position.x,input_rect.position.y,input_rect.size.x,input_rect.size.y],"options":[]})
  if (node is Label or node is RichTextLabel) and node.is_visible_in_tree():
   var rect=node.get_global_rect();result.append({"text":node.text,"kind":"Label","tooltip":"","disabled":true,"rect":[rect.position.x,rect.position.y,rect.size.x,rect.size.y],"options":[]})
  if node is Button and node.is_visible_in_tree():
   var rect=node.get_global_rect();var options=[]
   if node is OptionButton:
    for i in range(node.item_count):options.append(node.get_item_text(i))
   result.append({"text":node.text,"tooltip":node.tooltip_text,"disabled":node.disabled,"rect":[rect.position.x,rect.position.y,rect.size.x,rect.size.y],"options":options})
 JavaScriptBridge.eval("window.spiritUiElements="+JSON.stringify(result)+";",true)

func present_evolution(event):
 if is_instance_valid(evolution_presentation):evolution_presentation.queue_free()
 evolution_presentation=preload("res://src/evolution_show.gd").new();evolution_presentation.main=self;evolution_presentation.event=event;add_child(evolution_presentation)
 if audio:audio.play("discovery")
