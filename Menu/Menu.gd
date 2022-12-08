extends Control

onready var main = $CenterContainer/Main
onready var settings = $CenterContainer/Settings

signal sensitivity_change(value)

func _ready():
	get_tree().paused = true

func _unhandled_key_input(event):
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().paused = true
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		visible = true

func _on_PlayButton_pressed():
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	visible = false


func _on_SettingsButton_pressed():
	main.visible = false
	settings.visible = true

func _on_ExitButton_pressed():
	get_tree().quit()


func _on_BackButton_pressed():
	main.visible = true
	settings.visible = false


func _on_VolumeSlider_value_changed(value):
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"),value)


func _on_SensitivitySlider_value_changed(value):
	emit_signal("sensitivity_change",value)
