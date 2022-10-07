extends Node

"""
Simple Godot Logger by Binogure-Studio
https://github.com/binogure-studio/godot-simple-logger
Licensed under MIT License

Some modifications were made to adapt to this addon
This is not required for the addon to work
"""

const FLUSH_EVERY = 100
const LOGFILE_AMOUNT = 10
const LOGFILE_PATH = 'user://rabid-hole-punch-godot-%s.log'

const FORMAT = '%s - %s - %s'
const DEBUG = 'debug'
const INFO = 'info'
const WARNING = 'warning'
const ERROR = 'error'

var current_filename = get_logfilename()
var logfile = File.new()
var message_amount = 0

func _init():
	logfile.open(current_filename, File.WRITE)

func _exit_tree():
	_flush()

func get_logfilename():	
	var logfilename = null
	var last_modified_time = 0
	var file = File.new()

	for index in range(0, LOGFILE_AMOUNT):
		var filename = LOGFILE_PATH % [index]
		if not file.file_exists(filename):
			logfilename = filename
			break
	
	var modified_time = file.get_modified_time(filename)

	if modified_time < last_modified_time or last_modified_time == 0:
		last_modified_time = modified_time
		logfilename = filename

	file.close()
	return logfilename

func debug(message):
	if OS.is_debug_build():
		_log(DEBUG, message)

func info(message):
	_log(INFO, message)

func warning(message):
	_log(WARNING, message, true)

func error(message):
	_log(ERROR, message, true)

func _format_time():
	var time = OS.get_time()
	return '%02d:%02d:%02d' % [time.hour, time.minute, time.second]

func _log(level, message, flush = false):
	var log_message = FORMAT % [_format_time(), level, message]

	logfile.store_line(log_message)
	message_amount += 1

	if flush or message_amount > FLUSH_EVERY:
		_flush()

	# Output to stdout
	if OS.is_debug_build():
		print(log_message)

func _flush():
	message_amount = 0

	if logfile != null:
		logfile.close()

	logfile = File.new()
	logfile.open(current_filename, File.READ_WRITE)
	logfile.seek_end()
