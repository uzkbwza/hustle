class_name MultiplayerClient

# The URL we will connect to.
#const SERVER_URL = "ws://localhost:52450"
#const SERVER_URL = "ws://168.235.81.168:52450"
#const SERVER_IP = "localhost"
# Our WebSocketClient instance.
var _client = WebSocketClient.new()
var connected = false

var address

signal connection_ended()
signal connection_succeeded()

func _init(address):
	self.address = address
	# Connect base signals to get notified of connection open, close, and errors.
	_client.connect("connection_failed", self, "_closed", [], CONNECT_DEFERRED)
	_client.connect("server_disconnected", self, "_closed", [], CONNECT_DEFERRED)
	_client.connect("connection_succeeded", self, "_connected", [], CONNECT_DEFERRED)

	# Initiate connection to the given URL.
	var err = _client.connect_to_url(address, PoolStringArray(["binary"]), true)
	if err != OK:
		print("Unable to connect")
		end_connection()

func get_client():
	return _client

func end_connection():
	emit_signal("connection_ended")
	_client.disconnect_from_host()

func _closed():
	# was_clean will tell you if the disconnection was correctly notified
	# by the remote peer before closing the socket.
	print("closed connection.")
	end_connection()

func _connected():
	connected = true
	print("connected to server at " + str(address))
	emit_signal("connection_succeeded")

func poll():
	_client.poll()
