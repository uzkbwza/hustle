extends Node

class_name LanDiscovery

const MAGIC_PROBE = "HUSTLE_LAN_PROBE:1"
const MAGIC_ROOM = "HUSTLE_LAN_ROOM:1"
const DISCOVERY_PORT = 52451
const ROOM_TTL_MS = 8000
const PROBE_INTERVAL_MS = 1200
const UNICAST_SCAN_INTERVAL_MS = 4000

signal rooms_changed(rooms)

var advertising = false
var browsing = false

var room_name = ""
var room_host = ""
var room_port = 0
var room_players = 1
var room_version = ""
var room_id = ""

var _advertise_socket = null
var _browse_socket = null
var _rooms = {}
var _last_probe_ms = 0
var _last_unicast_scan_ms = 0
var _last_signature = ""

func start_advertising(p_room_name, p_host_name, p_port, p_players=1):
	stop_advertising()
	room_name = str(p_room_name)
	room_host = str(p_host_name)
	room_port = int(p_port)
	room_players = int(p_players)
	room_version = str(Global.VERSION)
	room_id = "%d-%d" % [OS.get_ticks_usec(), randi()]
	_advertise_socket = PacketPeerUDP.new()
	var err = _advertise_socket.listen(DISCOVERY_PORT)
	if err != OK:
		print("LanDiscovery: could not listen on port " + str(DISCOVERY_PORT) + " (" + str(err) + ")")
		_advertise_socket.close()
		_advertise_socket = null
		return err
	advertising = true
	set_process(true)
	return OK

func stop_advertising():
	advertising = false
	if _advertise_socket != null:
		_advertise_socket.close()
	_advertise_socket = null
	room_name = ""
	room_host = ""
	room_port = 0
	room_players = 1
	room_version = ""
	room_id = ""

func update_players(count):
	room_players = int(count)

func start_browsing():
	if browsing:
		return OK
	if _browse_socket != null:
		_browse_socket.close()
		_browse_socket = null
	_browse_socket = PacketPeerUDP.new()
	_browse_socket.set_broadcast_enabled(true)
	var err = _browse_socket.listen(0)
	if err != OK:
		print("LanDiscovery: could not open browse socket (" + str(err) + ")")
		_browse_socket.close()
		_browse_socket = null
		return err
	browsing = true
	_rooms.clear()
	_last_signature = ""
	_last_probe_ms = 0
	_last_unicast_scan_ms = 0
	set_process(true)
	return OK

func stop_browsing():
	if _browse_socket != null:
		_browse_socket.close()
		_browse_socket = null
	if !browsing:
		return
	browsing = false
	_rooms.clear()
	_last_signature = ""
	emit_signal("rooms_changed", [])

func refresh():
	_last_probe_ms = 0
	_last_unicast_scan_ms = 0

func get_rooms():
	var now = OS.get_ticks_msec()
	var rooms = []
	for key in _rooms.keys():
		var room = _rooms[key]
		if now - int(room.get("seen", 0)) > ROOM_TTL_MS:
			_rooms.erase(key)
			continue
		var copy = room.duplicate()
		copy.erase("seen")
		rooms.append(copy)
	rooms.sort_custom(self, "_sort_room")
	return rooms

func _sort_room(a, b):
	var an = str(a.get("name", "")).to_lower()
	var bn = str(b.get("name", "")).to_lower()
	if an == bn:
		return str(a.get("ip", "")) < str(b.get("ip", ""))
	return an < bn

func _process(_delta):
	if advertising and _advertise_socket != null:
		_poll_advertise()
	if browsing and _browse_socket != null:
		_poll_browse()
	if !advertising and !browsing:
		set_process(false)

func _poll_advertise():
	while _advertise_socket.get_available_packet_count() > 0:
		var packet = _advertise_socket.get_packet()
		if packet.get_string_from_ascii() != MAGIC_PROBE:
			continue
		_advertise_socket.set_dest_address(_advertise_socket.get_packet_ip(), _advertise_socket.get_packet_port())
		_advertise_socket.put_packet(_room_payload().to_utf8())

func _room_payload():
	return JSON.print({
		"magic": MAGIC_ROOM,
		"id": room_id,
		"name": room_name,
		"host": room_host,
		"port": room_port,
		"players": room_players,
		"version": room_version,
	})

func _poll_browse():
	var now = OS.get_ticks_msec()
	if now - _last_probe_ms >= PROBE_INTERVAL_MS:
		_last_probe_ms = now
		_send_probe()
	while _browse_socket.get_available_packet_count() > 0:
		_handle_room_packet(_browse_socket.get_packet(), _browse_socket.get_packet_ip())
	_emit_if_changed()

func _send_probe():
	var probe = MAGIC_PROBE.to_utf8()
	for target in _probe_targets():
		_browse_socket.set_dest_address(target, DISCOVERY_PORT)
		_browse_socket.put_packet(probe)
	var now = OS.get_ticks_msec()
	if now - _last_unicast_scan_ms >= UNICAST_SCAN_INTERVAL_MS:
		_last_unicast_scan_ms = now
		for target in _unicast_targets():
			_browse_socket.set_dest_address(target, DISCOVERY_PORT)
			_browse_socket.put_packet(probe)

func _probe_targets():
	var targets = ["255.255.255.255", "127.0.0.1"]
	for addr in _local_ipv4_addresses():
		var parts = str(addr).split(".")
		var subnet = "%s.%s.%s.255" % [parts[0], parts[1], parts[2]]
		if !(subnet in targets):
			targets.append(subnet)
	return targets

func _local_ipv4_addresses(include_virtual=true):
	var addresses = []
	for addr in IP.get_local_addresses():
		if !_is_ipv4(addr) or addr.begins_with("127.") or addr.begins_with("169.254."):
			continue
		if !include_virtual and _is_virtual_address(addr):
			continue
		if !(addr in addresses):
			addresses.append(addr)
	return addresses

func _is_virtual_address(addr):
	return addr.begins_with("192.168.56.") or addr.begins_with("192.168.137.") or addr.begins_with("192.168.99.") or addr.begins_with("172.17.") or addr.begins_with("172.18.") or addr.begins_with("172.19.")

func _unicast_targets():
	var targets = []
	for addr in _local_ipv4_addresses(false):
		var parts = str(addr).split(".")
		var prefix = "%s.%s.%s." % [parts[0], parts[1], parts[2]]
		for host in range(1, 255):
			var target = prefix + str(host)
			if target == addr or target in targets:
				continue
			targets.append(target)
	return targets

func _handle_room_packet(packet, ip):
	var parsed = JSON.parse(packet.get_string_from_utf8())
	if parsed.error != OK or !(parsed.result is Dictionary):
		return
	var data = parsed.result
	if str(data.get("magic", "")) != MAGIC_ROOM:
		return
	var game_port = int(data.get("port", 0))
	if game_port <= 0:
		return
	var found_id = str(data.get("id", ""))
	if advertising and found_id != "" and found_id == room_id:
		return
	var key = found_id
	if key == "":
		key = "%s:%d" % [ip, game_port]
	_rooms[key] = {
		"ip": ip,
		"port": game_port,
		"name": str(data.get("name", "")),
		"host": str(data.get("host", "")),
		"players": int(data.get("players", 1)),
		"version": str(data.get("version", "")),
		"seen": OS.get_ticks_msec(),
	}

func _emit_if_changed():
	var rooms = get_rooms()
	var signature = JSON.print(rooms)
	if signature == _last_signature:
		return
	_last_signature = signature
	emit_signal("rooms_changed", rooms)

func _is_ipv4(addr):
	var parts = str(addr).split(".")
	if parts.size() != 4:
		return false
	for part in parts:
		if !part.is_valid_integer():
			return false
		var n = int(part)
		if n < 0 or n > 255:
			return false
	return true
