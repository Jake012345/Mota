extends Node2D

var spawn_point: Vector2 = Vector2.ZERO
onready var map: TileMap = get_node("World")

var generator_params: Dictionary = {
   "s_map_size_x": 500,           #  "s_..." s_ stands for setting, telling the algorythm taht it is not a loadable resource
   "s_map_size_y": 500,
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
         "s_size": 20,
         "s_weight": 2,
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
         "s_size": 10,
         "s_weight": 1,
         "s_is_bordered": false
        },
      "2": { # area index 2
         "s_difficulty": 1,
         "s_size": 10,
         "s_weight": 1,
         "s_is_bordered": false
        }
     }
  }

func _ready():
   randomize()
   pass

func _physics_process(delta):
   
   pass


func load_in_enemies():   ### hehe will be rewritten soon ofc
   pass


func generate_map(params: Dictionary = generator_params):
   var gen_tileset: TileSet = TileSet.new()
   parse_dict(params, gen_tileset)
   map.cell_y_sort = true
   map.tile_set = gen_tileset
   ## using noise to generate aras
   var area_markers: Dictionary = generate_areas(params)
   apply_areas_on_map(area_markers)
   pass

func find_nearest_point(point: Vector2, points: Array, cell_map: Dictionary, cell_size: int) -> Array:
   var nearest_point: Vector2i = Vector2i(INF, INF)
   var nearest_distance: float = INF

   # Determine the cell of the current point
   var cell = Vector2(point.x / cell_size, point.y / cell_size)

   # Check neighboring cells in a 3x3 grid
   for x_offset in range(-1, 2):
      for y_offset in range(-1, 2):
         var neighbor_cell = cell + Vector2(x_offset, y_offset)
         if not cell_map.has(neighbor_cell):
            continue

         # Check points in the neighboring cell
         for other_point in cell_map[neighbor_cell]:
            if point == other_point:
               continue

            var distance = point.distance_to(other_point)
            if distance < nearest_distance:
               nearest_distance = distance
               nearest_point = other_point

   return [nearest_point, nearest_distance]

func generate_areas(params: Dictionary) -> Dictionary:
   var area_markers: Array = [] # of Vector2 : x, y
   var area_marker_parser: Array = []  # index based matching, contains the area_id
   var area_cumulative_weights: Array = []
   var area_cumulative_weight_sum: int = 0
   var cell_map: Dictionary = {} # Spatial partitioning grid
   var cell_size: int = 50  # Adjust based on your map size and density
   var weight_sum: int = 0
   var greatest_area_size: int = 0
   
   #calculate greatest area size and weight helpers
   for i in params["areas"]:
      greatest_area_size = max(greatest_area_size, params["areas"][i]["s_size"])
      weight_sum += params["areas"][i]["s_weight"]
      area_cumulative_weights.append(params["areas"][i]["s_weight"])
      area_cumulative_weight_sum += params["areas"][i]["s_weight"]

   # 
   for i in range(params["s_map_size_x"]):
      for j in range(params["s_map_size_y"]):
         var set: bool = false
         if not area_markers.empty(): # selecting all area centers based on distance to already selected ones
            var distance_ok: bool = true
            for tmp_area_index in range(area_markers.size()):
               var min_distance: float = pow(params["areas"][str(area_marker_parser[tmp_area_index])]["s_size"] + greatest_area_size, 2)
               if Vector2(area_markers[tmp_area_index]).distance_squared_to(Vector2(i, j)) < min_distance:
                  distance_ok = false
            if distance_ok:
               area_markers.append(Vector2i(i, j))
               set = true
         else:  # selecting the first ever area (top left) with 10% chance (prob wont affect anything anyways)
            if not randi() % 10:
               area_markers.append(Vector2i(i, j))
               set = true
         if set:
            var selected: int = area_cumulative_weights.size() - 1 # the last as base value
            var weight_seed: int = randi() % area_cumulative_weight_sum
            var weight_counter: int = 0
            for c in range(area_cumulative_weights.size()):
               weight_counter += area_cumulative_weights[c]
               if weight_counter > weight_seed:
                  selected = c
                  break
            area_marker_parser.append(selected)
   
   var return_dict: Dictionary = {}
   for i in range(area_markers.size()):
      return_dict[area_markers[i]] = area_marker_parser[i]
   return return_dict
   pass


func apply_areas_on_map(area_markers: Dictionary):
   # Setting area centers on map
   for i in area_markers.keys():
      map.set_cellv(i, generator_params["default_map_tiles"][str(area_markers[i])])

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
