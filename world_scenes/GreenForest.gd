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

func find_nearest_point(point: Vector2, points: Array) -> Array:
   var nearest_point: Vector2 = Vector2.ZERO
   var nearest_distance: float = INF

   for other_point in points:
      if point == other_point:
         continue  # Skip the current point

      var distance = point.distance_to(other_point)
      if distance < nearest_distance:
         nearest_distance = distance
         nearest_point = other_point
   return [nearest_point, nearest_distance]

func generate_map(params: Dictionary = generator_params):
   var gen_tileset: TileSet = TileSet.new()
   parse_dict(params, gen_tileset)
   map.cell_y_sort = true
   map.tile_set = gen_tileset
   ## using noise to generate aras
   var area_markers:Dictionary = generate_areas(params)
   apply_areas_on_map(area_markers)
   pass

func generate_areas(params: Dictionary) -> Dictionary:
   var area_markers: Dictionary = {}
   for i in range(params["s_map_size_x"]):  #creating the noise value set
      for j in range(params["s_map_size_y"]): #### !!!!!!!!!!!!!!!!!!!!!!!!!!!### Set Density and rarity for biomes dynamically
         if not int(rand_range(0, 10)):
            area_markers[Vector2(i, j)] = "0"
            continue
         if not int(rand_range(0, 10)):
            area_markers[Vector2(i, j)] = "1"
            continue
         if not int(rand_range(0, 10)):
            area_markers[Vector2(i, j)] = "2"
            continue

   var points = area_markers.keys()  # List of Vector2 keys
   while points.size() > 1:  # Loop while there are more than one point
      var current_point = points[0]  # Start from the first point
      var tmp = find_nearest_point(current_point, points)
      var nearest_point: Vector2 = tmp[0]
      var nearest_distance: float = tmp[1]
      
      var delete_range = generator_params["areas"] \
       [area_markers[current_point]]["s_min_size"] + \
       generator_params["areas"] \
       [area_markers[nearest_point]]["s_min_size"]

      if nearest_point and nearest_distance <= delete_range:
         # Delete the nearest point from the dictionary and the list
         area_markers.erase(nearest_point)
         points.erase(nearest_point)
      else:
         # If no points to delete, move to the next point
         points.pop_front()
   return area_markers
   pass

func apply_areas_on_map(area_markers: Dictionary):
   # Setting area centers on map
   for i in area_markers:
      map.set_cellv(i, generator_params["default_map_tiles"][area_markers[i]])

   # Filling the map up with nearest area's elements
   for i in range(generator_params["s_map_size_x"]):
      for j in range(generator_params["s_map_size_y"]):
         var closest_area: Vector2 = Vector2.ZERO
         for area in area_markers:
               if closest_area == Vector2.ZERO or \
                  Vector2(i, j).distance_squared_to(area) < Vector2(i, j).distance_squared_to(closest_area):
                  closest_area = area
         map.set_cell(i, j, map.get_cellv(closest_area))
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
