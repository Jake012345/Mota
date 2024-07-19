extends Node
class_name Profile

var player_name: String = ""

func load_in(dir_path: String):
   player_name = dir_path.split("/")[-1]
   pass
