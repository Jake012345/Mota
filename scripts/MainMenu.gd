extends Control

var peer: NetworkedMultiplayerENet = null
onready var options_menu: TabContainer = get_node("TabsMenu")
var world_name: String = ""
var world_description: String = ""
onready var edit_world_name: LineEdit = get_node("TabsMenu/MenuHost/HBoxContainer/VBoxContainerOptions/EditWorldName")
onready var edit_world_description: LineEdit = get_node("TabsMenu/MenuHost/HBoxContainer/VBoxContainerOptions/EditWorldDescription")
onready var edit_player_count: SpinBox = get_node("TabsMenu/MenuHost/HBoxContainer/VBoxContainerOptions/EditPlayerCount")
onready var edit_server_ip: LineEdit = get_node("TabsMenu/MenuConnect/TabsConnectionModes/DirectConnect/HBoxContainerDirectConnect/VBoxContainerOptions/EditServerIp")
onready var edit_server_port: SpinBox = get_node("TabsMenu/MenuConnect/TabsConnectionModes/DirectConnect/HBoxContainerDirectConnect/VBoxContainerOptions/EditServerPort")
onready var label_current_profile: Label = get_node("LabelCurrentProfile")
onready var list_profiles: ItemList = get_node("TabsMenu/MenuProfile/VBoxContainerProfile/ListProfiles")
onready var popup_profile_namer: Popup = get_node("TabsMenu/MenuProfile/PopupProfileNamer")
onready var button_accept_profile_namer: Button = get_node("TabsMenu/MenuProfile/PopupProfileNamer/Panel/ButtonAccept")
onready var button_cancel_profile_namer: Button = get_node("TabsMenu/MenuProfile/PopupProfileNamer/Panel/ButtonCancel")
onready var edit_profile_namer: LineEdit = get_node("TabsMenu/MenuProfile/PopupProfileNamer/Panel/LineEdit")
onready var connect_menu: TabContainer = get_node("TabsMenu/MenuConnect/TabsConnectionModes")
var max_players: int
var has_save: bool = false
var game_scene_root: String = "res://scenes/Game.tscn"
onready var server_list_item_base: PackedScene = preload("res://classes/list_item_custom.tscn")
onready var server_list: ScrollContainer = get_node("TabsMenu/MenuConnect/TabsConnectionModes/ServerList/VBoxContainerServerList/ScrollContainer")
onready var server_list_items: VBoxContainer = get_node("TabsMenu/MenuConnect/TabsConnectionModes/ServerList/VBoxContainerServerList/ScrollContainer/VBoxContainer")


func _ready():
   Network.connect("connected_to_server", self, "join_game")
   Network.connect("server_hosted", self, "join_game")
   GlobalDatabase.connect("profile_chosen", self, "update_current_profile_label")
   GlobalDatabase.load_profiles()
   load_profiles()
   pass

func get_peer():
   if Network.get_peer() != null:
      peer = Network.get_peer()
   else:
      print("")
   pass

func set_menu_to(tab_index):
   if options_menu.current_tab != tab_index:
      options_menu.current_tab = tab_index
      if tab_index == 1: ## CONNECT MODE
         Network.server_listener.connect("new_server", self, "update_server_list")
         Network.server_listener.connect("remove_server", self, "update_server_list")
         Network.search_for_server()
      else:
         Network.server_listener.disconnect("new_server", self, "update_server_list")
         Network.server_listener.disconnect("remove_server", self, "update_server_list")
         Network.stop_searching()
         update_server_list("") # since we are not syncing the servers one by one but all together, we need to reset them when changing to other tabs
   pass

func host_server(): # CALLS Network.host_server()
   max_players = int(edit_player_count.value)
   world_name = edit_world_name.text
   world_description = edit_world_description.text
   
#only starts with real name, only whitespace name is not allowed
   if clear_spaces(world_name):
      Network.server_name = world_name
      Network.server_description = clear_spaces(world_description)
      Network.host_server(edit_server_port.value, max_players)
   pass

func clear_spaces(text):
   while "  " in text:
      text = text.format([" "], "  ")
   text = text.strip_edges()
   if text != "" and text != " ":
      return text
   else:
      return ""
   pass


func connect_to_server(ip: String = edit_server_ip.text, port: int = int(edit_server_port.value)):
   Network.connect_to_server(ip, port)
   pass

func join_game():
   if get_tree().change_scene(game_scene_root) == OK:
      print("Joined server")
   else:
      print("Could not load in world")
   pass

func update_current_profile_label():
   label_current_profile.text = "Current profile: " + GlobalDatabase.active_profile.name
   pass

func load_profiles():
   list_profiles.clear()
   for i in GlobalDatabase.profiles:
      list_profiles.add_item(i)
   pass


func create_profile():
   edit_profile_namer.text = ""
   popup_profile_namer.popup_centered()
   button_accept_profile_namer.connect("pressed", self, "create_profile_accepted")
   button_cancel_profile_namer.connect("pressed", self, "create_profile_cancelled")
   pass

func create_profile_accepted():
   if edit_profile_namer.text != "":
      GlobalDatabase.create_profile(edit_profile_namer.text)
      button_accept_profile_namer.disconnect("pressed", self, "create_profile_accepted")
      button_cancel_profile_namer.disconnect("pressed", self, "create_profile_cancelled")
      popup_profile_namer.hide()
      load_profiles()
   pass

func create_profile_cancelled():
   edit_profile_namer.text = ""
   popup_profile_namer.hide()
   button_accept_profile_namer.disconnect("pressed", self, "create_profile_accepted")
   button_cancel_profile_namer.disconnect("pressed", self, "create_profile_cancelled")
   pass

func remove_profile():
   if list_profiles.get_selected_items().size() > 0:
      var warning: ConfirmationDialog = ConfirmationDialog.new()
      self.add_child(warning)
      warning.owner = self
      warning.popup_exclusive = true
      warning.window_title = "Confirm deletion!"
      warning.dialog_text = ("Do you want to remove the following profile?\n- " + list_profiles.get_item_text(list_profiles.get_selected_items()[0]))
      warning.popup_centered()
      warning.connect("confirmed", self, "remove_profile_accepted", [list_profiles.get_item_text(list_profiles.get_selected_items()[0])])
   pass

func remove_profile_accepted(p_name):
   GlobalDatabase.remove_profile(p_name)
   load_profiles()
   pass

func edit_profile():
   if list_profiles.get_selected_items().size() > 0:
      edit_profile_namer.text = list_profiles.get_item_text(list_profiles.get_selected_items()[0])
      edit_profile_namer.caret_position = edit_profile_namer.text.length()
      popup_profile_namer.popup_centered()
      button_accept_profile_namer.connect("pressed", self, "edit_profile_accepted")
      button_cancel_profile_namer.connect("pressed", self, "edit_profile_cancelled")
   pass

func edit_profile_accepted():
   if edit_profile_namer.text != "":
      GlobalDatabase.edit_profile(list_profiles.get_item_text(list_profiles.get_selected_items()[0]), edit_profile_namer.text)
      button_accept_profile_namer.disconnect("pressed", self, "edit_profile_accepted")
      button_cancel_profile_namer.disconnect("pressed", self, "edit_profile_cancelled")
      popup_profile_namer.hide()
      load_profiles()
   pass

func edit_profile_cancelled():
   edit_profile_namer.text = ""
   popup_profile_namer.hide()
   button_accept_profile_namer.disconnect("pressed", self, "edit_profile_accepted")
   button_cancel_profile_namer.disconnect("pressed", self, "edit_profile_cancelled")
   pass

func set_profile():
   if list_profiles.get_selected_items().size() > 0:
      GlobalDatabase.set_active_profile(list_profiles.get_item_text(list_profiles.get_selected_items()[0]))
   pass

func set_connect_mode_to(to):
   connect_menu.current_tab = to
   pass

func update_server_list(ip): #we dont need the ip because we refresh all servers on a new server or on losig one, meaning that a lot of changes on the list can affect user experience in a bad way (reseting the currently viewed one)
   for i in server_list_items.get_children():
      i.queue_free()
   for i in Network.server_listener.knownServers:
      var item: list_item_custom = add_server_list_item()
      item.set_text(Network.server_listener.knownServers[i]["name"])
      item.set_description(Network.server_listener.knownServers[i]["description"])
      item.set_ip(i)
      item.set_port(Network.server_listener.knownServers[i]["port"])
      item.set_player_limit(Network.server_listener.knownServers[i]["player_limit"])
   pass

func add_server_list_item():
   var server_list_item: list_item_custom = server_list_item_base.instance()
   server_list_items.add_child(server_list_item)
   server_list_item.connect("expanded", self, "server_list_collapse_all") #will be called with arg: self --> being excluded as the EXCEPT param
   server_list_item.connect("connect_pressed", self, "connect_to_server")
   return server_list_item
   pass

func server_list_collapse_all(except: list_item_custom = null):
   for i in server_list_items.get_children():
      if i != except:
         i.collapse()
      else:
         continue
   pass
