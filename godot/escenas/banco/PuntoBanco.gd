extends Area2D
## Punto de acceso a los servicios de ventanilla o cajero.

@export_enum("ventanilla", "cajero") var modo: String = "ventanilla"
@export var texto_indicador: String = "E: usar banco"

@onready var _indicador: Label = $Indicador
var _jugador_cerca: bool = false


func _ready() -> void:
	_indicador.text = texto_indicador
	body_entered.connect(_al_entrar_en_rango)
	body_exited.connect(_al_salir_del_rango)


func _al_entrar_en_rango(cuerpo: Node2D) -> void:
	if cuerpo is CharacterBody2D:
		_jugador_cerca = true
		_indicador.visible = true


func _al_salir_del_rango(cuerpo: Node2D) -> void:
	if cuerpo is CharacterBody2D:
		_jugador_cerca = false
		_indicador.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if not _jugador_cerca:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E:
		get_viewport().set_input_as_handled()
		# En la ventanilla atiende una persona: primero se conversa con ella.
		if modo == "ventanilla":
			var atencion := get_tree().get_first_node_in_group("atencion_ui")
			if atencion != null:
				atencion.call("abrir_atencion")
				return
		var interfaz := get_tree().get_first_node_in_group("banco_ui")
		if interfaz == null:
			push_warning("No se encontró la interfaz del banco.")
			return
		interfaz.call("abrir_banco", modo)
