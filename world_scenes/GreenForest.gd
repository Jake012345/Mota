extends Node2D

var spawn_point: Vector2 = Vector2.ZERO
onready var map: TileMap = get_node("World")

var generator_params: Dictionary = {
   "s_map_size_x": 100,           #  "s_..." s_ stands for setting, telling the algorythm taht it is not a loadable resource
   "s_map_size_y": 100,
   "s_is_map_bordered": true,
   "default_map_borders": {
      "right": {
         "1": "res://textures/GreenForest/world/ground/tile058.png"
        },
      "left": {
         "1": "res://textures/GreenForest/world/ground/tile058.png"
        },
      "top": {
         "1": "res://textures/GreenForest/world/ground/tile058.png"
        },
      "bottom": {
         "1": "res://textures/GreenForest/world/ground/tile058.png"
        },
      "top_right": {
         "1": "res://textures/GreenForest/world/ground/tile058.png"
        },
      "top_left": {
         "1": "res://textures/GreenForest/world/ground/tile058.png"
        },
      "bottom_right": {
         "1": "res://textures/GreenForest/world/ground/tile058.png"
        },
      "bottom_left": {
         "1": "res://textures/GreenForest/world/ground/tile058.png"
        }
      },
   "default_map_tiles" : {
      "0": "res://textures/GreenForest/world/ground/tile000.png",
      "1": "res://textures/GreenForest/world/ground/tile004.png",
      "2": "res://textures/GreenForest/world/ground/tile010.png"
     },
   "areas": {
      "0": { # area index 0
         "s_difficulty": 1,
         "s_min_size": 10,
         "s_max_size": 20,
         "s_rarity": 1,
         "s_is_bordered": true,
         "border": {            # <--- only if IS_BORDERED
            "right": {
               "s_atlas_id": -1,
               "s_tile_id": -1,
               "s_collision_width":8
              }
           },
         "border_hitbox_sizes":{
            "s_right":5,
            "s_left":5,
            "s_top":5,
            "s_bottom":5
           },
         "tiles": {               #     the tiles will have the relative rarity of 1:3:5  ## PROB NOT, dumb idea (1:1) ?
            #"1": "res://16x16_single_tile_png",
            #"3": "res://16x16_single_tile_png",
            #"5": "res://16x16_single_tile_png",
           }
        },
      "1": { # area index 1
         "s_difficulty": 1,
         "s_min_size": 10,
         "s_max_size": 20,
         "s_rarity": 1,
         "s_is_bordered": false
        },
      "2": { # area index 2
         "s_difficulty": 1,
         "s_min_size": 10,
         "s_max_size": 20,
         "s_rarity": 1,
         "s_is_bordered": false
        }
     }
  }

func _physics_process(delta):
   
   pass


func load_in_enemies():   ### hehe will be rewritten soon ofc
   pass

func generate_map(params: Dictionary = generator_params):
   var gen_tileset: TileSet = TileSet.new()
   parse_dict(params, gen_tileset)
   map.cell_y_sort = true
   map.tile_set = gen_tileset
   ## using noise
   var area_markers: Dictionary = {}
   for i in range(params["s_map_size_x"]):  #creating the noise value set
      for j in range(params["s_map_size_y"]): #### !!!!!!!!!!!!!!!!!!!!!!!!!!!### Set Density and rarity for biomes dynamically
         if not int(rand_range(0, 10)):
            area_markers[Vector2(i, j)] = "0"
         if not int(rand_range(0, 10)):
            area_markers[Vector2(i, j)] = "1"
         if not int(rand_range(0, 10)):
            area_markers[Vector2(i, j)] = "2"
            
   # A kulcsok listája, amit szűrni fogunk
   var keys: Array = area_markers.keys()
   # A szűrt kulcsokat tároló lista
   var filtered_keys = []
   # Addig folytatjuk, amíg van elem a keys listában
   while keys.size() > 0:
      # Az aktuális vizsgálandó kulcs az első elem a listában
      var key: Vector2 = keys.pop_front()  # Eltávolítjuk és elmentjük
      # Hozzáadjuk ezt a kulcsot a szűrt kulcsok listájához
      filtered_keys.append(key)
      # Készítünk egy új listát, amely csak a megfelelő távolságú kulcsokat tartalmazza
      var new_keys: Array = []
      
      # Végigmegyünk a maradék kulcsokon
      for i in keys:
         # Megnézzük, hogy a 'key' és az 'i' közötti távolság legalább "limit"-e
         if key.distance_to(i) >= generator_params["areas"][area_markers[i]]["s_min_size"] + \
            generator_params["areas"][area_markers[key]]["s_min_size"]:
               # Ha a távolság nagyobb vagy egyenlő 1000-rel, hozzáadjuk az új listához
               new_keys.append(i)
      
      # A maradék kulcsokat tartalmazó új listával felülírjuk a keys változót
      keys = new_keys

   # Miután a kulcsokat kiszűrtük, a szűrt elemek alapján módosítjuk az eredeti dictionary-t
   for i in area_markers.keys():
      # Ha egy kulcs nincs benne a szűrt listában, eltávolítjuk az eredeti dictionary-ből
      if not filtered_keys.has(i):
         area_markers.erase(i)



   for i in area_markers:  # applying noise result
      var area_id = area_markers[i]
      map.set_cellv(i, generator_params["default_map_tiles"][str(area_id)]) # not default map tiles is the best here
   pass

func parse_dict(dict: Dictionary, tileset: TileSet): # changing the res-paths to their cell index after importing them
   
   for i in dict:
      if typeof(dict[i]) == TYPE_DICTIONARY:
         if len(dict[i]) > 0:              ## still parseable subdict
            parse_dict(dict[i], tileset)
         else:
            print(i, " ", "not specified/filled") ## empty subdict
      else:
         if typeof(dict[i]) == TYPE_STRING: ## string value
            if i.substr(0, 2) == "s_":     ## setting with string value
               pass
            else: ## string non setting --> loadable asset
               dict[i] = load_map_tile(tileset, dict[i])
         else: # not string and not dict value
            if i.substr(0, 2) == "s_": #non-string setting
               pass
   pass

func load_map_tile(tileset: TileSet, path: String):
   var id: int = 0
   if tileset.get_tiles_ids().size() > 0:
      id = tileset.get_tiles_ids().max() + 1
   else:
      id = 0
   tileset.create_tile(id)
   tileset.tile_set_texture(id, load(path))
   return id
   pass
