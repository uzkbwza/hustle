extends VBoxContainer

export var player_id = 1

signal style_selected(style)

var selected_style = null
var aura_particle = null
onready var load_style_button = $"%LoadStyleButton"

func _ready():
	$"%PlayerLabel".text = "P1" if player_id == 1 else "P2"
	$"%CharacterPortrait".flip_h = player_id != 1
	$"%LoadStyleButton".connect("style_selected", self, "_on_style_selected")

func _on_style_selected(style):
	emit_signal("style_selected", style)
	selected_style = style
	if aura_particle:
		aura_particle.queue_free()
		aura_particle = null
	var material = $"%CharacterPortrait".get_material()
	material.set_shader_param("color", Color.white)
	material.set_shader_param("use_outline", false)
#	$"%CharacterPortrait".get_material().set_shader_param("extra_replace_color_1", false)
#	$"%CharacterPortrait".get_material().set_shader_param("extra_replace_color_2", false)
	if style:
		Custom.apply_style_to_material(style, $"%CharacterPortrait".get_material(), true)

		if style.show_aura:
			var particle = preload("res://fx/CustomTrailParticle.tscn").instance()
			$"%CharacterPortrait".add_child(particle)
			particle.load_settings(style.aura_settings)
			particle.position = $"%CharacterPortrait".rect_size / 2
			particle.scale.x = -1 if player_id == 2 else 1
			particle.facing = -1 if player_id == 2 else 1
			aura_particle = particle
			pass

func load_last_style():
	$"%LoadStyleButton".load_last_style()

func init():
	$"%LoadStyleButton".player_id = player_id
	$"%CharacterLabel".text = ""
#	$"%CharacterPortrait".texture = null
	set_enabled(true)
	$"%LoadStyleButton".save_style = true
	$"%LoadStyleButton".update_styles()
	$"%LoadStyleButton".hide()
	if SteamHustle.STARTED and (!Network.multiplayer_active or player_id == Network.player_id):
		$"%LoadStyleButton".show()

func load_character_data(data):
	$"%CharacterPortrait".texture = data["portrait"]
	$"%CharacterLabel".text = data["name"]
	var material = $"%CharacterPortrait".get_material()
	material.set_shader_param("extra_replace_color_1", data.get("extra_color_1"))
	material.set_shader_param("extra_replace_color_2", data.get("extra_color_2"))
	_on_style_selected(selected_style)

func set_enabled(on):
	for child in get_children():
		child.visible = on
		$"%LoadStyleButton".save_style = on

