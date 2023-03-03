extends Node

class_name ProfanityFilter

const arr_bad = [
'faggot',
'shit',
'fuck',
'jigaboo',
'jiggaboo',
'jiggerboo',
'kike',
'nig nog',
'nigga',
'nigger',
'pussy',
'gook',
'raping',
'rapist',
'shemale',
'slanteye',
'towelhead',
'tranny',
'white pride',
]

static func filter(text: String):
	var mask = ["!", "@", "#", "$", "%", "^", "~"]
	randomize()
	for word in arr_bad:
		var replacement = ""
		for i in range(len(word)):
			replacement += mask[randi() % mask.size()]
		text = text.replacen(word, replacement)
	return text
