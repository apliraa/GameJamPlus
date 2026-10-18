extends AnimatedSprite2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if(animation != $Eyes.animation):
		$Eyes.animation = animation
		
	if(animation != $Helm.animation):
		$Helm.animation = animation
		
	if(animation != $Plate.animation):
		$Plate.animation = animation
	
	if(animation != $Boots.animation):
		$Boots.animation = animation
		
func play_animations(target_animation : String):
	animation = target_animation
	play()
	$Eyes.play()
	$Plate.play()
	$Boots.play()
	$Helm.play()
	
		
