extends SceneTree
var game
var assets={}
var out="/workspace/spirit-isles-online/web/ui-pictures/"
func _initialize():run.call_deferred()
func add(texture):
 if texture==null:return
 var key=game.mobile.texture_key(texture)
 if assets.has(key):return
 var image=texture.get_image()
 if image==null or image.is_empty():push_error("Missing image: "+key);return
 var name=key.sha256_text().substr(0,24)+".png";var result=image.save_png(out+name)
 if result!=OK:push_error("Cannot export "+key);return
 assets[key]="ui-pictures/"+name
func run():
 DirAccess.make_dir_recursive_absolute(out);game=load("res://main.tscn").instantiate();root.add_child(game);await process_frame
 for id in game.rules.data.IDS:
  for stage in range(1,int(game.rules.data.family(id).stage_count)+1):add(game.visuals.sprite_texture({"family":id,"stage":stage}))
 for type in game.visuals.TYPE_COLORS:add(game.visuals.icon(type))
 for i in range(48):add(game.skin.indexed(i))
 for i in range(16):add(game.people.texture(i))
 for i in range(8):add(game.people.texture(i,true))
 for name in DirAccess.get_files_at("res://assets/ui-v05"):
  if name.ends_with(".png") or name.ends_with(".svg"):add(game.skin.texture(name))
 for path in ["res://assets/gacha-v07.png","res://assets/world-map-v04.png"]:add(load(path))
 var file=FileAccess.open("/workspace/spirit-isles-online/web/ui-assets.js",FileAccess.WRITE);file.store_string("window.spiritMobileAssetIndex="+JSON.stringify(assets)+";\n");file.close()
 print("MOBILE_UI_ASSETS_EXPORTED count=",assets.size());game.free();quit()
