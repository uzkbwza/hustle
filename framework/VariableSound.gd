extends AudioStreamPlayer

class_name VariableSound

export var pitch_variation = 0.1
export var one_shot = false
export var streams: Array = []
var pitch_scale_

var rng = BetterRng.new()
# Declare member variables here. Examples:
# var a = 2
# var b = "text"

func _ready():
	rng.randomize()
	pitch_scale_ = pitch_scale
	if autoplay:
		play()
	if one_shot:
		connect("finished", self, "queue_free")

# Called when the node enters the scene tree for the first time.
func play(p=0.0):
	if len(streams) > 0:
		stream = rng.choose(streams)
	pitch_scale = pitch_scale_ + rng.randf_range(-pitch_variation, pitch_variation)
	.play(p)
