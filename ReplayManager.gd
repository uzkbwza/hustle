extends Node

var frames = {
	1: {},
	2: {},
}

var playback = false setget set_playback

var resimulating = false
var resim_tick = false

func set_playback(p):
	playback = p

func init():
	frames = {
		1: {},
		2: {},
	}
