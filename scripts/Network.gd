extends Node

var ip: String = "127.0.0.1"
var default_port: int = 57546
var port: int = default_port
var client_limit: int = 1
var server_description: String = ""
var peer: NetworkedMultiplayerENet = NetworkedMultiplayerENet.new()
var server_id: int = 1
var server_name: String = ""
var clients: Dictionary = {}
var enemies: Dictionary = {}
var own_id: int
var is_connected_to_server: bool = false
signal server_hosted
signal connected_to_server
signal starter_map_received
signal server_disconnected
signal disconnected_from_server
var server_advertiser: ServerAdvertiser = ServerAdvertiser.new()
var server_listener: ServerListener = ServerListener.new()

func _ready():
   peer.connect("connection_failed", self, "connection_failed")
   peer.connect("connection_succeeded", self, "connected_to_server")
   peer.connect("peer_connected", self, "client_connected")
   peer.connect("peer_disconnected", self, "client_disconnected")
   peer.connect("server_disconnected", self, "server_disconnected")
   rpc_config("notify_client_own_id", MultiplayerAPI.RPC_MODE_REMOTESYNC)
   rpc_config("introducing_to_server", MultiplayerAPI.RPC_MODE_REMOTESYNC)
   rpc_config("sync_client_positions", MultiplayerAPI.RPC_MODE_REMOTESYNC)
   rpc_config("notify_client_of_map", MultiplayerAPI.RPC_MODE_REMOTESYNC)
   rpc_config("sync_clients_starter_values", MultiplayerAPI.RPC_MODE_REMOTESYNC)
   rpc_config("client_movement", MultiplayerAPI.RPC_MODE_REMOTESYNC)
   rpc_config("client_is_ready_for_world", MultiplayerAPI.RPC_MODE_REMOTESYNC)
   pass 

func advertise_server(server_port: int = port, server_name: String = "New Server", server_desc: String = ""):
   server_advertiser.broadcastPort = server_advertiser.broadcastPort #needs to be changed only in case of conflict
   server_advertiser.serverInfo["port"] = server_port
   server_advertiser.serverInfo["name"] = server_name
   server_advertiser.serverInfo["player_limit"] = client_limit
   server_advertiser.serverInfo["description"] = server_description
   print("Broadcasting server data")
   self.add_child(server_advertiser)  # starts on tree_entered()
   pass

func stop_advertising():
   if server_advertiser.get_parent() == self:
      self.remove_child(server_advertiser)
   server_advertiser = ServerAdvertiser.new()
   pass

func search_for_server(listening_port: int = server_listener.listenPort):
   server_listener.listenPort = listening_port
   if not (server_listener.get_parent() == self):
      self.add_child(server_listener) # starts on tree_entered()
   pass

func stop_searching():
   if server_listener.get_parent() == self:
      self.remove_child(server_listener)
      server_listener = ServerListener.new()
   pass

func reset_peer():
   peer.close_connection()
   get_tree().network_peer = null
   clients.clear()
   own_id = 0
   pass

func host_server(server_port: int = port, player_limit: int = client_limit):   #### WE DONT NEED SERVER IP, DO WE?  May all be the same?
   reset_peer()
   port = server_port
   var error = peer.create_server(port, player_limit)
   if error != 0:
      print("Hosting Server Failed. " + String(error))
   else:
      print("Server Created Successfully and runs at: [" + ip + ":" + String(port) + "]")
      get_tree().network_peer = peer
      own_id = server_id
      clients[own_id] = GlobalDatabase.own_data
      print("Own ID is determined as: " + String(own_id))
      emit_signal("server_hosted")
      introducing_to_server(own_id, GlobalDatabase.own_data)
      is_connected_to_server = true
      client_is_ready_for_world(own_id)
      advertise_server(server_port, server_name)
   pass

func connect_to_server(server_ip: String = ip, server_port: int = port):   
   reset_peer()
   var error = peer.create_client(server_ip, server_port)
   if error == 0:
      print("Peer Established Successfully! \n Connecing to server...")
   else:
      print("Setting Up Peer Failed. " + String(error))
   get_tree().network_peer = peer
   pass

func disconnect_from_server():
   if not is_network_server():
      print("Disconnecting From Server... [" + String(peer.get_peer_address(1)), ":" + String(peer.get_peer_port(1)) + "]")
   else:
      print("Shutting down server...")
      stop_advertising()
   reset_peer()
   if peer.get_connection_status() == 0:
      print("Successfully Disconected!")
      is_connected_to_server = false
      emit_signal("disconnected_from_server")
   pass

func connected_to_server():
   print("Successfully Connected To Server! [" + String(peer.get_peer_address(1)) + ":" + String(peer.get_peer_port(1)) + "]")
   clients[1] = ""
   emit_signal("connected_to_server")
   is_connected_to_server = true
   pass

func client_connected(client_id):
   print("Incoming Connection Established Successfully: " + String(client_id))
   if get_tree().is_network_server():
      rpc_id(client_id, "notify_client_own_id", client_id)
   pass

func server_disconnected():
   print("Server Disconnected.")
   is_connected_to_server = false
   emit_signal("server_disconnected")
   pass

func client_disconnected(client_id):  #called on everyone
   print("Client Disconnected: " + String(client_id))
   clients.erase(client_id)
   pass

func connection_failed():
   print("Failed To Connect To The Server.")
   pass

func get_peer():
   if peer.get_connection_status() == 2:
      return peer
   else:
      return null
   pass

func notify_client_own_id(id):  ##Server calls it on client with client's id
   own_id = id
   print("Own Id is determined as: " + String(own_id))
   rpc_id(server_id, "introducing_to_server", own_id, GlobalDatabase.own_data)
   pass

func introducing_to_server(id: int, data: Dictionary): #Client calls it on server with own data
   if own_id == server_id:
      clients[id] = data
      rpc("sync_clients_starter_values", clients)
   pass

func sync_clients_starter_values(data): #server calls it on clients with the whole clients data dict
   if own_id != server_id:
      clients = data
      rpc_id(server_id, "client_is_ready_for_world", own_id)
   pass

func client_is_ready_for_world(client_id: int): # called on server when the client/server loaded in the game state
   if own_id == server_id:
      if client_id == server_id: # then its called by the server where it is called (self called)
         GlobalDatabase.current_map = GlobalDatabase.starter_map
         emit_signal("starter_map_received")
      else:
         rpc_id(client_id, "notify_client_of_map", GlobalDatabase.current_map)
   pass

func notify_client_of_map(map: String = ""): #called on clients on join
   if own_id != server_id:
      if map != "":
         GlobalDatabase.current_map = map
         emit_signal("starter_map_received")
   pass

func _physics_process(delta):
   if GlobalDatabase.ready_for_game and is_connected_to_server and own_id == 1:
      rpc_unreliable("sync_client_positions", GlobalDatabase.server_player_positions, GlobalDatabase.server_player_directions)
      pass
   pass

func sync_client_positions(pos, dir): ## called on clients
   if own_id != server_id:
      GlobalDatabase.server_player_positions = pos
      GlobalDatabase.server_player_directions = dir
   pass

func self_movement(direction):
   GlobalDatabase.server_player_directions[own_id] = direction
   rpc_unreliable_id(server_id ,"client_movement", own_id, direction)
   pass

func client_movement(id, direction): ## called on master
   if get_tree().is_network_server():
      GlobalDatabase.server_player_directions[id] = direction
   pass
