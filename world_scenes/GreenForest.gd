extends Node2D

var enemy_pumpkin_root: PackedScene = load("res://classes/enemy_pumpkin_basic.tscn")
var spawn_point: Vector2 = Vector2.ZERO

export var generator_params: Dictionary = {
   "map_size_x": 10,
   "map_size_y": 10,
   "is_map_bordered": true,
   "default_border": {
      
     }
  }

""" GENERATOR DATA

var generator_params: Dictionary = 
{
   "map_size_x": 10,
   "map_size_y": 10,
   "is_map_bordered": true,
   "default_map_border":  {
      "right":"res://16x16_single_tile.png"
      "left":"res://16x16_single_tile.png"
      "top":"res://16x16_single_tile.png"
      "bottom":"res://16x16_single_tile.png"
      }
   "areas": {
      area_name_1: {
         "difficulty": 1,
         "rarity": 1,
         "is_bordered": false,
         "borders": {             <--- only if IS_BORDERED
            "right": "res://16x16_single_tile.png",
            "left": "res://16x16_single_tile.png",
            "top": "res://16x16_single_tile.png",
            "bottom": "res://16x16_single_tile.png",
           }
         "tiles": {                    the tiles will have the relative rarity of 1:3:5
            1: "res://16x16_single_tile_png",
            3: "res://16x16_single_tile_png",
            5: "res://16x16_single_tile_png",
           }
        },
      area_name_2:{}
     }
  }

"""

func _physics_process(delta):
   
   pass


func load_in_enemies():   ### hehe will be rewritten soon ofc
   pass
