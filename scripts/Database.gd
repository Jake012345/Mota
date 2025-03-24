extends Node

var database_file: File = File.new()
var documents_folder: Directory = Directory.new()
var profiles_folder: Directory = Directory.new()
var documents_folder_path: String = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS) + "/Mota"
var profiles_folder_path: String = documents_folder_path + "/Profiles"
#var saves_folder: String = documents_folder + "/Saves"
var profiles: Array = []
var active_profile: Profile = null
var active_profile_pointer: File = File.new()
var active_profile_pointer_path: String = profiles_folder_path + "/active.txt"
signal profile_chosen
var starter_map: String = "res://world_scenes/GreenForest.tscn"
var current_map: String = ""
var own_data: Dictionary = {}
var ready_for_game: bool = false
var server_player_directions: Dictionary = {}
var server_player_positions: Dictionary = {}
var max_name_char: int = 15
var chunk_size: int  # Needs to be synced as well
var map_cell_size: int = 32
var map_size_x: int
var map_size_y: int


func _ready():
   connect("profile_chosen", self, "refresh_own_data")
   pass

func refresh_own_data():
   own_data["name"] = active_profile.player_name
   if Network.peer.get_connection_status() == 2: #connected
      Network.introducing_to_server(Network.own_id, own_data)
      pass
   pass

func load_profiles():
   profiles = []
   randomize()
   if not documents_folder.dir_exists(documents_folder_path):
      documents_folder.make_dir(documents_folder_path)
   documents_folder.open(documents_folder_path)
   if not profiles_folder.dir_exists(profiles_folder_path):
      profiles_folder.make_dir(profiles_folder_path)
   profiles_folder.open(profiles_folder_path)

   profiles_folder.list_dir_begin(true, true)
   var item = profiles_folder.get_next()
   while item != "":
      if profiles_folder.current_is_dir():
         profiles.append(item)
      item = profiles_folder.get_next()
   print("Loaded in " + String(profiles.size()) + " profile(s).")

   var new_profile: String = ""
   if profiles.size() == 0:
      new_profile = "Default" + String(randi())
      create_profile(new_profile)
      print("No proflies found.\n " + new_profile + " created.")
      active_profile_pointer.open(active_profile_pointer_path, File.WRITE)
   else:
      new_profile = ""
      if active_profile_pointer.file_exists(active_profile_pointer_path):
         active_profile_pointer.open(active_profile_pointer_path, File.READ)
         new_profile = active_profile_pointer.get_as_text().strip_edges()
         if new_profile == "":
            new_profile = choose_first_profile()
            active_profile_pointer.open(active_profile_pointer_path, File.WRITE)
         else: ##need to test if is a valid profile
            if not(new_profile in profiles):
               active_profile_pointer.open(active_profile_pointer_path, File.WRITE)
               new_profile = choose_first_profile()
      else:
         active_profile_pointer.open(active_profile_pointer_path, File.WRITE)
         new_profile = choose_first_profile()
   set_active_profile(new_profile)
   active_profile_pointer.close()
   pass

func choose_first_profile():
   profiles_folder.open(profiles_folder_path)
   profiles_folder.list_dir_begin(true, true)
   var p = profiles_folder.get_next()
   while not profiles_folder.current_is_dir():
      p = profiles_folder.get_next()
   return p
   pass

func set_active_profile(p_name: String):
   var dir_checker: Directory = Directory.new()
   if dir_checker.dir_exists(profiles_folder_path + "/" + p_name):
      var profile: Profile = Profile.new()
      profile.name = p_name
      profile.load_in(profiles_folder_path + "/" + p_name)
      active_profile = profile
      active_profile_pointer.open(active_profile_pointer_path, File.WRITE)
      active_profile_pointer.store_string(p_name)
      active_profile_pointer.close()
      emit_signal("profile_chosen")
   else:
      print("Selected profile missing!")
   pass

func create_profile(p_name: String):
   if not(p_name in profiles) and p_name != "":
      profiles_folder.make_dir(profiles_folder_path + "/" + p_name)
      profiles.append(p_name)
   else:
      print("Profile already exists!")
   pass

func remove_profile(p_name: String):
   if OS.move_to_trash(profiles_folder_path + "/" + p_name) == OK:
      profiles.erase(p_name)
      print("Profile [" + p_name + "] was removed.")
   else:
      print("Profile removal was unsuccessful.")
   pass

func edit_profile(p_name: String, new_name: String = ""):
   if p_name != "" and new_name != "":
      if profiles_folder.rename(profiles_folder_path + "/" + p_name, profiles_folder_path + "/" + new_name) == OK:
         profiles.erase(p_name)
         profiles.append(new_name)
      else:
         print("Profile renaming was unsuccessful.")
      pass
   pass
