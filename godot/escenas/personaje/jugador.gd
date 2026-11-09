
extends CharacterBody2D

@export var velocidad: float = 100.0

func _physics_process(_delta: float) -> void:
	var direccion = Input.get_vector(
		"ui_left",
		"ui_right",
		"ui_up",
        "ui_down"
	)

	velocity = direccion * velocidad
	move_and_slide()
