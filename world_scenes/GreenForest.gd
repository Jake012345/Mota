extends Node2D

var spawn_point: Vector2 = Vector2.ZERO
onready var map: Dictionary = {}   ### stored map
onready var world: Dictionary = {} ### client only, actual world

var generator_params: Dictionary = {
   "s_map_size_x": 200,           #  "s_..." s_ stands for setting, telling the algorythm that it is not a loadable resource
   "s_map_size_y": 200,          # both must be a multiplied value of GlobalDatabase.chunk_size
   "s_is_map_bordered": true,
   "s_sampling_steps": 30,
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
   draw_world()  # should put to a better place, some _draw() bind...
   pass


func load_in_enemies():   ### hehe will be rewritten soon ofc
   pass


func generate_map(params: Dictionary = generator_params):
   var gen_tileset: TileSet = TileSet.new()
   parse_dict(params, gen_tileset)
   ## using noise to generate aras
   var area_markers: Dictionary = generate_areas(params)
   init_map(generator_params, true, gen_tileset)
   apply_areas_on_map(area_markers)
   pass

func init_map(params: Dictionary, y_sort: bool, tile_set: TileSet):
   for i in range(GlobalDatabase.map_size_x / GlobalDatabase.chunk_size):
      for j in range(GlobalDatabase.map_size_y / GlobalDatabase.chunk_size):
         var tmp_tilemap: TileMap = TileMap.new()
         tmp_tilemap.cell_size = Vector2i(GlobalDatabase.map_cell_size, GlobalDatabase.map_cell_size)
         tmp_tilemap.cell_y_sort = y_sort
         tmp_tilemap.tile_set = tile_set
         self.add_child(tmp_tilemap)
         tmp_tilemap.owner = self
         tmp_tilemap.position = Vector2i(
            i * GlobalDatabase.chunk_size * GlobalDatabase.map_cell_size, \
            j * GlobalDatabase.chunk_size * GlobalDatabase.map_cell_size
         )
         tmp_tilemap.visible = false
         var tmp_dict: Dictionary = {}
         map[Vector2i(i, j)] = tmp_dict
         world[Vector2i(i,j)] = tmp_tilemap
   pass

func generate_areas(params: Dictionary) -> Dictionary:
   
   var area_cumulative_weights: Array = []
   var area_cumulative_weight_sum: int = 0
   var weight_sum: int = 0
   var area_min_size: int = params["areas"][params["areas"].keys()[0]]["s_size"]
   var area_max_size: int = params["areas"][params["areas"].keys()[0]]["s_size"]

   #calculate greatest area size and weight helpers
   for i in params["areas"]:
      weight_sum += params["areas"][i]["s_weight"]
      area_cumulative_weights.append(params["areas"][i]["s_weight"])
      area_cumulative_weight_sum += params["areas"][i]["s_weight"]
      area_min_size = min(area_min_size, params["areas"][i]["s_size"])
      area_max_size = max(area_max_size, params["areas"][i]["s_size"])
   
   GlobalDatabase.chunk_size = floor(area_min_size/sqrt(2)) # for 2D map :)

   var chunks: Dictionary = {}
   for i in range(params["s_map_size_x"] / GlobalDatabase.chunk_size):
      for j in range(params["s_map_size_y"] / GlobalDatabase.chunk_size):
         var tmp_chunk: Dictionary = {}
         chunks[Vector2i(i, j)] = tmp_chunk
         
   return poisson(
      params,
      area_min_size,
      area_max_size,
      area_cumulative_weights,
      area_cumulative_weight_sum,
      params["s_sampling_steps"]
   )
   pass


func poisson(
   params: Dictionary,
   smallest_radius: int,
   biggest_radius: int,
   area_cumulative_weights: Array,
   area_cumulative_weight_sum: int,
   try_limit: int = 30
   ) -> Dictionary:

   var N = 2 # Dimension
   var area_markers: Dictionary = {}
   var poisson_grid: Dictionary = {}
   var poisson_active_points: Array = [] # actives, that can look for neighbours
   var cell_size = GlobalDatabase.chunk_size # one cell's side in the poisson grid
   GlobalDatabase.chunk_size = cell_size
   GlobalDatabase.map_size_x = floor(params["s_map_size_x"] - params["s_map_size_x"] % cell_size)
   GlobalDatabase.map_size_y = floor(params["s_map_size_y"] - params["s_map_size_y"] % cell_size)
   var first_point: Vector2i = Vector2i(randi() % GlobalDatabase.map_size_x, randi() % GlobalDatabase.map_size_y)
   var cells_dimension_lenght:Vector2i = Vector2i(
      ceil(GlobalDatabase.map_size_x / cell_size) + 1,
      ceil(GlobalDatabase.map_size_x / cell_size) + 1
      )
   for i in cells_dimension_lenght.x:
      for j in cells_dimension_lenght.y:
         var tmp_cell: Dictionary = {}
         poisson_grid[Vector2i(i, j)] = tmp_cell
   
   var area_type: int = roll_area_type(params, area_cumulative_weights, area_cumulative_weight_sum)
   poisson_insert(poisson_grid, first_point, area_type, cell_size)
   #area_markers[first_point] = area_type   not needed?
   poisson_active_points.append(first_point)
   
   while poisson_active_points.size() > 0:
      # selecting a random point so the areas wont generate in a linear way, making them more random
      # althouh, we might lose the ability to control neighbouring area markers (apart from the type generation)
      var selected_active: Vector2i = poisson_active_points[randi() % poisson_active_points.size()]
      var is_valid: bool = false
      var try_count: int = 0
      while try_count < try_limit and not is_valid: # stops after max (sampling_steps) step (30)
         var generated_point: Vector2i = roll_point_distance_with_rotation(
            selected_active,
            smallest_radius,
            biggest_radius
         )
         var generated_type: int = roll_area_type(params, area_cumulative_weights, area_cumulative_weight_sum)
         
         if is_valid_point(params, poisson_grid, cell_size, biggest_radius, generated_point, generated_type):
            poisson_active_points.append(generated_point)
            poisson_insert(poisson_grid, generated_point, generated_type, cell_size)
            is_valid = true
         try_count += 1
      if not is_valid:
         poisson_active_points.erase(selected_active)
   
   for i in poisson_grid:
      if poisson_grid[i].size() > 0:
         area_markers[i] = poisson_grid[i]
   return area_markers
   pass

func is_valid_point(
   params: Dictionary,
   grid: Dictionary,
   cell_size: int,
   biggest_radius: int,
   point: Vector2i,
   point_type: int) -> bool:

   # calculating the amount of cells the function has to check, it will text an x * x area
   if (point.x < 0 or point.x >= GlobalDatabase.map_size_x) or \
      (point.y < 0 or point.y >= GlobalDatabase.map_size_y):
      return false
   else:
      var cell_x = floor(point.x / cell_size)
      var cell_y = floor(point.y / cell_size)
      var point_range: int = params["areas"][str(point_type)]["s_size"]
      var area_size_to_check: int = ceil(biggest_radius + point_range) / cell_size
      # we only work in positive coordinates (0 and N+) to make it support negatives, we should replace 0 with absolute pos of the map grid's x/y coordinates
      var top_left_corner: Vector2i = Vector2i(max(0, cell_x - floor(area_size_to_check / 2)), max(0, cell_y - floor(area_size_to_check / 2)))
      var bottom_right_corner: Vector2i = Vector2i(min(GlobalDatabase.map_size_x / cell_size, cell_x + ceil(area_size_to_check / 2)), min(GlobalDatabase.map_size_y / cell_size, cell_y + ceil(area_size_to_check / 2)))
      for i in range(top_left_corner.x, bottom_right_corner.x):
         for j in range(top_left_corner.y, bottom_right_corner.y):
            if grid[Vector2i(i, j)].size() == 0:
               continue
            else:
               # by the algorythm, it is guaranteed, that one cell contains upmost one point
               var tested_point_range: int = params["areas"][str(grid[Vector2i(i, j)][grid[Vector2i(i, j)].keys()[0]])]["s_size"]
               if Vector2(point).distance_to(grid[Vector2i(i, j)].keys()[0]) < tested_point_range + point_range:
                  return false
      return true
   pass

func roll_area_type(params: Dictionary, area_cumulative_weights: Array, area_cumulative_weight_sum: int) -> int:
   var area_weight_seed: int = randi() % area_cumulative_weight_sum
   var area_weight_counter: int = 0
   var area_index: int = 0
   
   while area_weight_counter < area_weight_seed:
      area_weight_counter += area_cumulative_weights[area_index]
      area_index += 1

   return area_index
   pass

func roll_point_distance_with_rotation(point: Vector2i, distance_min: int, distance_max: int) -> Vector2i:
   var alpha: float = randi() % 360
   var radius: float = rand_range(distance_min, distance_max)
   var new_x: float = point.x + radius * cos(deg2rad(alpha))
   var new_y: float = point.y + radius * sin(deg2rad(alpha))
   
   return Vector2i(int(new_x), int(new_y))
   pass

func poisson_insert(grid: Dictionary, point: Vector2i, value: int, cell_size: int):
   var x: int = floor(point.x / cell_size)
   var y: int = floor(point.y / cell_size)
   grid[Vector2i(x, y)][Vector2i(point.x, point.y)] = value
   pass

func apply_areas_on_map(area_markers: Dictionary):   ## VORONOI ?
   # Setting area centers on map
   for i in area_markers.keys():
      var chunk_pos: Vector2i = i
      var subchunk_pos: Vector2i = area_markers[i].keys()[0]
      var area_type: int = area_markers[chunk_pos][subchunk_pos]

#### STILL O(n^2) WHEN ASSIGNING AREA MARKERS ################x
   # Filling the map up with nearest area's elements
   for i in range(GlobalDatabase.map_size_x):
      for j in range(GlobalDatabase.map_size_y):
         var closest_area: Vector2i = Vector2.INF
         var chunk_pos: Vector2i = Vector2i(floor(i / GlobalDatabase.chunk_size), floor(j / GlobalDatabase.chunk_size))
         var closest_area_type: int
         for chunk in area_markers.keys():
            if Vector2(i, j).distance_squared_to(area_markers[chunk].keys()[0]) < Vector2(i, j).distance_squared_to(closest_area):
               closest_area = area_markers[chunk].keys()[0]
               closest_area_type = area_markers[chunk][closest_area]
         map[chunk_pos][Vector2i(i % GlobalDatabase.chunk_size, j % GlobalDatabase.chunk_size)] = closest_area_type

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

func draw_world(load_range: int = -500): # load range to all direction so 30 means a 60 wider screen
   if get_viewport().get_camera_2d() != null:
      var camera = get_viewport().get_camera_2d()  # Ha a Camera2D a scriptben van, állítsd be megfelelően!
      var viewport_size = get_viewport_rect().size
      var zoom_factor: Vector2 = camera.zoom

      # A látható méret kiszámítása a zoom figyelembevételével
      var visible_size = viewport_size * zoom_factor
      var visible_rect = Rect2(camera.global_position - visible_size / 2, visible_size)
      var chunk_area_size: int = GlobalDatabase.map_cell_size * GlobalDatabase.chunk_size
      
      for i in world:
         
         if is_chunk_on_screen(visible_rect, chunk_area_size, world[i], load_range):
            if load_chunk(i):
               world[i].visible = true
            else: # error
               push_error("Could not load chunk")
         else:
            world[i].visible = false

   pass

func is_chunk_on_screen(visible_rect: Rect2i, chunk_area_size, chunk: TileMap, load_range) -> bool:
   var chunk_rect: Rect2 = Rect2(chunk.position, Vector2i(chunk_area_size, chunk_area_size))
   var extended_screen: Rect2 = Rect2(visible_rect.position - Vector2i(load_range, load_range), Vector2i(visible_rect.size + Vector2i(load_range*2, load_range*2)))
   
   return extended_screen.intersects(chunk_rect)
   pass

func load_chunk(key: Vector2i) -> bool:
   var chunk: TileMap = world[key]
   for i in GlobalDatabase.chunk_size:
      for j in GlobalDatabase.chunk_size:
         chunk.set_cellv(Vector2i(i, j), map[key][Vector2i(i, j)])
   return true
   
   pass
