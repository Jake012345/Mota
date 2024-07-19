extends NinePatchRect
class_name list_item_custom

onready var texture_basic: Texture = load("res://textures/UI/Border and Panels Menu Part 1/01 Border 01.png")
onready var texture_expanded: Texture = load("res://textures/UI/Border and Panels Menu Part 1/02 Border 01.png")
onready var button_item: Button = get_node("ButtonItem")
onready var label_name: Label = get_node("VBoxContainer/HBoxContainerUpper/LabelName")
onready var label_description: Label = get_node("VBoxContainer/VBoxContainerLower/LabelDescription")
onready var button_connect_texture: NinePatchRect = get_node("VBoxContainer/VBoxContainerLower/HBoxContainer/NinePatchRect")
onready var button_connect: Button = get_node("VBoxContainer/VBoxContainerLower/HBoxContainer/NinePatchRect/ButtonConnect")
onready var label_players: Label = get_node("VBoxContainer/HBoxContainerUpper/LabelPlayerLimit")
onready var button_collapse_holder: NinePatchRect = get_node("VBoxContainer/HBoxContainerUpper/NinePatchRect")
signal expanded
signal connect_pressed
export var min_height: int = 40
export var max_height: int = 100
export var description: String = ""
export var player_count: int = 0
export var player_limit: int = 0
var ip: String  = ""
var port: int = 0

func _ready():
   collapse()
   pass

func resized():
   
   pass

func expand():
   button_item.disabled = true
   label_name.margin_left = 10
   label_name.margin_top = 10
   label_name.rect_size = Vector2(0, 0)
   label_name.align = Label.ALIGN_LEFT
   rect_min_size.y = max_height
   emit_signal("expanded", self)
   texture = texture_expanded
   label_description.show()
   button_connect_texture.show()
   button_collapse_holder.show()
   pass

func collapse():
   button_item.disabled = false
   button_item.pressed = false
   rect_min_size.y = min_height
   texture = texture_basic
   label_description.hide()
   button_connect_texture.hide()
   button_collapse_holder.hide()
   pass

func connect_pressed():
   emit_signal("connect_pressed", ip, port)
   pass

func set_text(text:String):
   label_name.text = text
   label_name.rect_size = Vector2(0, 0)
   pass

func clear_text():
   label_name.text.clear()
   label_name.rect_size = Vector2(0, 0)
   pass

func get_text():
   return label_name.text
   pass

func set_description(text: String):
   label_description.text = text
   pass

func clear_description():
   label_description.text.clear()
   pass

func get_description():
   return label_description.text
   pass

func set_ip(text: String):
   ip = text
   pass

func clear_ip():
   ip.clear()
pass

func get_ip():
   return ip
   pass

func set_port(number: int):
   port = number
   pass

func clear_port():
   port = 0
   pass

func get_port():
   return port
   pass

func set_player_limit(number: int):
   pass

func clear_player_limit():
   player_limit = 0
   pass

func get_player_limit():
   return player_limit
   pass
