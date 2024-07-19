extends Node2D


var main_menu_path: String = "res://scenes/MainMenu.tscn"
var current_world: Node2D = null
var player_character_root: PackedScene = preload("res://classes/player.tscn")
var characters: Dictionary = {}
var world_is_loaded: bool = false
var character_is_loaded: bool = false

func _ready():
   Network.connect("starter_map_received", self, "load_in_world")
   Network.connect("server_disconnected", self, "server_disconnected")
   Network.connect("disconnected_from_server", self , "disconnected_from_server")
   pass

func server_disconnected():
   get_tree().change_scene(main_menu_path)
   pass

func disconnected_from_server():
   get_tree().change_scene(main_menu_path)
   pass

func load_in_world():
   if not GlobalDatabase.current_map == "":
      var map: PackedScene = load(GlobalDatabase.current_map)
      if not map == null:
         current_world = map.instance()
         add_child(current_world)
         current_world.owner = self
         print("World loaded in successfully")
         world_is_loaded = true
         if current_world.has_method("load_in_enemies"):
            current_world.call("load_in_enemies")
         else:
            print("Current world has no method to load in enemies")
      else:
         print("Invalid world path")
         Network.rpc_id(Network.server_id, "client_is_ready_for_world", Network.own_id)
   pass

func load_in_players():
   if world_is_loaded:
      if Network.clients.size() > characters.size():
         for i in Network.clients.keys():
            if not i in characters and Network.clients[i].size() > 0:  ### because physics process loads in players and tics between clients index and value creation, resulting in working with an empty key
               var character: entity = player_character_root.instance()
               current_world.add_child(character)
               character.owner = current_world
               character.name = String(i)
               character.position = Vector2(300, 300)  ### where to set spawn?
               character.show()
               character.z_index  = 10
               characters[i] = character
               character.set_base_stats(Network.clients[i])
      character_is_loaded = true
      if Network.clients.size() < characters.size():
         for i in characters:
            if not i in Network.clients:
               characters[i].call_deferred("free")
               characters.erase(i)
   pass

func load_in_enemies():
   #if world_is_loaded
   pass

func _physics_process(delta):
   load_in_players()
   if not world_is_loaded:
      load_in_world()
      yield(get_tree().create_timer(1), "timeout")
      
   if world_is_loaded and character_is_loaded:
      GlobalDatabase.ready_for_game = true
   
      var direction: Vector2 = Vector2.ZERO
      if Input.is_action_pressed("right"):
         direction += Vector2.RIGHT
      if Input.is_action_pressed("left"):
         direction += Vector2.LEFT
      if Input.is_action_pressed("up"):
         direction += Vector2.UP
      if Input.is_action_pressed("down"):
         direction += Vector2.DOWN
      if Network.is_connected_to_server:
         if Network.is_connected_to_server:
            Network.self_movement(direction)
         
         if  Network.is_connected_to_server:
            if get_tree().is_network_server():
               for i in characters:
                  if i in GlobalDatabase.server_player_directions:
                     characters[i].move_and_slide(Vector2(GlobalDatabase.server_player_directions[i]).normalized() * characters[i].speed)
                     GlobalDatabase.server_player_positions[i] = characters[i].position
            else:
               for i in characters:
                  if i in GlobalDatabase.server_player_positions:
                     characters[i].position = GlobalDatabase.server_player_positions[i]
                  else:
                     GlobalDatabase.server_player_positions[i] = Vector2.ZERO
      if Input.is_action_just_pressed("ex"):
         Network.disconnect_from_server()
   pass
