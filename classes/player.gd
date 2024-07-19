extends entity  #>> KinematicBody2D 

var last_few_tic_pos: Array = []
var walk_animation_timeout_tic: int = 5
var moving: bool = false
onready var texture: AnimatedSprite = get_node("Texture")
 
func _ready():
   pass

func set_base_stats(stats: Dictionary = {}):
   if stats != null:
      entity_name = stats["name"]
      current_hp = max_hp
      pass

   else:
      print("Failed to load playerdata")
   pass

func _physics_process(delta):
   last_few_tic_pos.append(position)
   if last_few_tic_pos.size() > walk_animation_timeout_tic:
      last_few_tic_pos.pop_front()
   var tic = last_few_tic_pos[0]
   moving = false
   for i in last_few_tic_pos:
      if tic != i:
         moving = true
   
   if moving:
      if GlobalDatabase.server_player_directions[int(String(name))].x < 0:   ##SOMEWHY YOU CANT CONVERT name TO int ?!
         texture.play("walk_left")
      if GlobalDatabase.server_player_directions[int(String(name))].x > 0:
         texture.play("walk_right")
      if GlobalDatabase.server_player_directions[int(String(name))].y < 0:
         texture.play("walk_up")
      if GlobalDatabase.server_player_directions[int(String(name))].y > 0:
         texture.play("walk_down")
   else:
      texture.stop()
   pass
