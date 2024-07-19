extends Label

var shown: bool = false

func _process(delta):
   if Vector2(get_local_mouse_position() + Vector2(-rect_size.x/2, -rect_size.y/2)).length() < 5 and not shown:
      shown = true
      $AnimationPlayer.play("show")
   elif Vector2(get_local_mouse_position() + Vector2(-rect_size.x/2, -rect_size.y/2)).length() > 5 and shown:
      yield(get_tree().create_timer(1.0), "timeout")
      if Vector2(get_local_mouse_position() + Vector2(-rect_size.x/2, -rect_size.y/2)).length() > 5:
         shown = false
         $AnimationPlayer.play("hide")
   pass
