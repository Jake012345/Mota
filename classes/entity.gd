extends KinematicBody2D
class_name entity

export var alive: bool = false
export var current_hp: int = 0
export var max_hp: int = 0
export var hp_regen: int = 0
export var current_mana: int = 0
export var max_mana: int = 0
export var mana_regen: int = 0
export var current_energy: int = 0
export var max_energy: int = 0
export var energy_regen : int = 0
export var skills: Dictionary = {}  ## skill objects with respectable varaibles (skill xp/lvl)
export var damage: int = 0 # base dmg
#export var damage_type: String = ""
export var current_armor: int = 0
export var max_armor: int = 0
export var teams: Array = [] # TEAM OBJECTS teams are for players and even monsters (one can be in more teams e.g. every player is in "players" and might be in others) it is the base of behaviour of monsters
export var inventory: Array = []
export var velocity: Vector2 = Vector2.ZERO
export var speed: float = 0.0
export var width: int = 0
export var height: int = 0

export var entity_name: String = ""
export var name_visible: bool = false
export var stats_visible: bool = true
var label_name: Label = Label.new()
var stat_holder: VBoxContainer = VBoxContainer.new()
var hp_bar: TextureProgress = TextureProgress.new()
var mana_bar: TextureProgress = TextureProgress.new()
var energy_bar: TextureProgress = TextureProgress.new()
var armor_bar: TextureProgress = TextureProgress.new()

func _ready():
   self.add_child(stat_holder)
   stat_holder.add_child(label_name)
   stat_holder.add_child(hp_bar)
   stat_holder.add_child(mana_bar)
   stat_holder.add_child(energy_bar)
   stat_holder.add_child(armor_bar)
   label_name.align = Label.ALIGN_CENTER
   label_name.valign = Label.VALIGN_CENTER
   hp_bar.texture_over = load("res://textures/painted/health_bar_over.png")
   hp_bar.texture_progress = load("res://textures/painted/health_bar_inner.png")
   hp_bar.texture_under = load("res://textures/painted/health_bar_border.png")
   ## here comes the configuration of the status bars
   yield(get_tree().create_timer(0.1), "timeout")
   hp_bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
   hp_bar.rect_position.x = stat_holder.rect_size.x / 2 - hp_bar.rect_size.x / 2
   stat_holder.rect_position.x = -(stat_holder.rect_size.x / 2)
   stat_holder.rect_position.y = -(height/2 + stat_holder.rect_size.y)
   pass

func _physics_process(delta):
   if stats_visible:
      energy_bar.show()
      hp_bar.show()
      armor_bar.show()
      mana_bar.show()
   else:
      energy_bar.hide()
      hp_bar.hide()
      armor_bar.hide()
      mana_bar.hide()
   if name_visible:
      label_name.show()
   else:
      label_name.hide()
   if entity_name != label_name.text:
      label_name.text = entity_name
   hp_bar.max_value = max_hp
   hp_bar.value = current_hp
   ## and the rest
   pass
