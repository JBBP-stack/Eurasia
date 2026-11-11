extends Area2D
## Nevera interactiva: el sprite refleja si está abierta y cuánta comida queda.

const TEXTURA_CERRADA: Texture2D = preload("res://assets/objetos/nevera1.png")
const TEXTURA_ABIERTA_LLENA: Texture2D = preload("res://assets/objetos/nevera2.png")
const TEXTURA_ABIERTA_VACIA: Texture2D = preload("res://assets/objetos/nevera3.png")

@onready var _indicador: Label = $Indicador
@onready var _sprite: Sprite2D = $Sprite

var _jugador_cerca: bool = false
var _abierta: bool = false


func _ready() -> void:
	add_to_group("nevera_objeto")
	body_entered.connect(_al_entrar_en_rango)
	body_exited.connect(_al_salir_del_rango)
	EstadoJuego.estado_vital_actualizado.connect(_actualizar_apariencia)
	_actualizar_apariencia()


func _al_entrar_en_rango(cuerpo: Node2D) -> void:
	if cuerpo is CharacterBody2D:
		_jugador_cerca = true
		_indicador.visible = true


func _al_salir_del_rango(cuerpo: Node2D) -> void:
	if cuerpo is CharacterBody2D:
		_jugador_cerca = false
		_indicador.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if not _jugador_cerca or GestorPartida.hay_ventanas_abiertas():
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E:
		_consultar_existencias()
		get_viewport().set_input_as_handled()


func _consultar_existencias() -> void:
	var nevera_ui := get_tree().get_first_node_in_group("nevera_ui")
	if nevera_ui == null:
		push_warning("No se encontró la interfaz de la nevera.")
		return
	nevera_ui.call("abrir_nevera")


func cambiar_estado_abierta(abierta: bool) -> void:
	_abierta = abierta
	_actualizar_apariencia()


func _actualizar_apariencia() -> void:
	if not is_node_ready():
		return
	if not _abierta:
		_sprite.texture = TEXTURA_CERRADA
		_sprite.position = Vector2.ZERO
	else:
		_sprite.texture = TEXTURA_ABIERTA_LLENA if EstadoJuego.comida_disponible > 0 else TEXTURA_ABIERTA_VACIA
		_sprite.position = Vector2(10, 0)
