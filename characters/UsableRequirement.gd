extends Node

class_name UsableRequirement

export var method: String
export var args: Array
export var inverse = false


func check(host):
	return host.callv(method, args) != inverse
