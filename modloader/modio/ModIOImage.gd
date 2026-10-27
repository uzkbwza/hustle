extends Reference

const MAX_FRAMES := 256
const MAX_PIXELS := 64 * 1024 * 1024
const MAX_SOURCE_PIXELS := 2048 * 2048
const MAX_DECODE_MS := 500
const DEFAULT_DELAY := 0.1
const ICON_ATLAS := preload("res://ui/mobileicons/icons.png")
const ICON_SIZE := 16
const ICON_COLUMNS := 4
const ICON_ORDER := ["arrows", "chat", "collect", "dislike", "globe", "like", "menu",
	"predictions", "replay", "subscribe", "uncollect", "unsubscribe", "zoom"]


static func thumb_path(mod_id: String) -> String:
	return ModIO.CACHE_DIR + "/thumb_" + str(mod_id) + ".img"


static func read_cached_texture(cache_path: String, max_size: int = 0):
	var file = File.new()
	if not file.file_exists(cache_path):
		return null
	if file.open(cache_path, File.READ) != OK:
		return null
	var bytes = file.get_buffer(file.get_len())
	file.close()
	return texture_from_bytes(bytes, max_size)


static func icon(icon_name: String) -> AtlasTexture:
	var index = max(ICON_ORDER.find(icon_name), 0)
	var texture = AtlasTexture.new()
	texture.atlas = ICON_ATLAS
	texture.region = Rect2((index % ICON_COLUMNS) * ICON_SIZE,
		(index / ICON_COLUMNS) * ICON_SIZE, ICON_SIZE, ICON_SIZE)
	return texture


static func texture_from_bytes(bytes: PoolByteArray, max_size: int = 0):
	if bytes.size() == 0 or bytes.size() > ModIO.MAX_IMAGE_BYTES:
		return null
	if _is_gif(bytes):
		var animation = _decode_gif(bytes, max_size)
		if animation != null:
			return animation
	var image = Image.new()
	if image.load_png_from_buffer(bytes) != OK \
	and image.load_jpg_from_buffer(bytes) != OK \
	and image.load_webp_from_buffer(bytes) != OK:
		return null
	if max_size > 0:
		image = _resize_image(image, max_size)
	var texture = ImageTexture.new()
	texture.create_from_image(image, 0)
	return texture


static func _reader_remaining(data: PoolByteArray, cursor: Array) -> int:
	return data.size() - int(cursor[0])


static func _reader_u8(data: PoolByteArray, cursor: Array) -> int:
	var pos = int(cursor[0])
	if pos >= data.size():
		return 0
	cursor[0] = pos + 1
	return data[pos]


static func _reader_u16(data: PoolByteArray, cursor: Array) -> int:
	return _reader_u8(data, cursor) | (_reader_u8(data, cursor) << 8)


static func _reader_read(data: PoolByteArray, cursor: Array, count: int) -> PoolByteArray:
	if count <= 0:
		return PoolByteArray()
	var pos = int(cursor[0])
	var end = pos + count
	if end > data.size():
		end = data.size()
	cursor[0] = end
	return data.subarray(pos, end - 1)


static func _reader_skip(data: PoolByteArray, cursor: Array, count: int) -> void:
	cursor[0] = min(int(cursor[0]) + count, data.size())


static func _reader_text(data: PoolByteArray, cursor: Array, count: int) -> String:
	var result = ""
	var pos = int(cursor[0])
	var end = min(pos + count, data.size())
	while pos < end:
		result += char(data[pos])
		pos += 1
	cursor[0] = pos
	return result


static func _reader_blocks(data: PoolByteArray, cursor: Array) -> PoolByteArray:
	var result = PoolByteArray()
	while _reader_remaining(data, cursor) > 0:
		var size = _reader_u8(data, cursor)
		if size == 0:
			break
		result.append_array(_reader_read(data, cursor, size))
	return result


static func _is_gif(bytes: PoolByteArray) -> bool:
	return bytes.size() >= 6 \
		and bytes[0] == 0x47 \
		and bytes[1] == 0x49 \
		and bytes[2] == 0x46 \
		and bytes[3] == 0x38 \
		and (bytes[4] == 0x37 or bytes[4] == 0x39) \
		and bytes[5] == 0x61


static func _decode_gif(bytes: PoolByteArray, max_size: int):
	var cursor := [0]
	var signature = _reader_text(bytes, cursor, 6)
	if signature != "GIF87a" and signature != "GIF89a":
		return null
	var screen_width = _reader_u16(bytes, cursor)
	var screen_height = _reader_u16(bytes, cursor)
	if screen_width <= 0 or screen_height <= 0:
		return null
	if screen_width * screen_height > MAX_SOURCE_PIXELS:
		return null
	var packed = _reader_u8(bytes, cursor)
	_reader_u8(bytes, cursor)
	_reader_u8(bytes, cursor)
	var global_palette = PoolByteArray()
	if packed & 0x80:
		global_palette = _reader_read(bytes, cursor, (2 << (packed & 0x07)) * 3)

	var scale = 1.0
	var out_width = screen_width
	var out_height = screen_height
	if max_size > 0:
		var longest = screen_width if screen_width > screen_height else screen_height
		if longest > max_size:
			scale = float(max_size) / float(longest)
			out_width = int(screen_width * scale)
			out_height = int(screen_height * scale)
			if out_width < 1:
				out_width = 1
			if out_height < 1:
				out_height = 1

	var canvas = PoolByteArray()
	canvas.resize(out_width * out_height * 4)
	canvas.fill(0)

	var frames = []
	var delays = []
	var transparent_index = -1
	var disposal = 0
	var delay = DEFAULT_DELAY
	var loop_count = 0
	var started = OS.get_ticks_msec()
	var frame_limit = MAX_FRAMES
	var pixels = out_width * out_height
	var pixel_limit = int(MAX_PIXELS / pixels)
	if pixel_limit < frame_limit:
		frame_limit = pixel_limit
	if frame_limit < 1:
		frame_limit = 1

	while _reader_remaining(bytes, cursor) > 0 and frames.size() < frame_limit:
		var block = _reader_u8(bytes, cursor)
		if block == 0x3B:
			break
		if block == 0x21:
			var label = _reader_u8(bytes, cursor)
			if label == 0xF9:
				var size = _reader_u8(bytes, cursor)
				if size >= 4:
					var control = _reader_u8(bytes, cursor)
					disposal = (control >> 2) & 0x07
					delay = _reader_u16(bytes, cursor) * 0.01
					var transparent = _reader_u8(bytes, cursor)
					transparent_index = transparent if control & 0x01 else -1
					if size > 4:
						_reader_skip(bytes, cursor, size - 4)
				else:
					_reader_skip(bytes, cursor, size)
				_reader_blocks(bytes, cursor)
			elif label == 0xFF:
				var size = _reader_u8(bytes, cursor)
				var app = _reader_text(bytes, cursor, size)
				var data = _reader_blocks(bytes, cursor)
				if app == "NETSCAPE2.0" and data.size() >= 3 and data[0] == 1:
					loop_count = data[1] | (data[2] << 8)
			elif label == 0x01:
				_reader_skip(bytes, cursor, _reader_u8(bytes, cursor))
				_reader_blocks(bytes, cursor)
			else:
				_reader_blocks(bytes, cursor)
			continue
		if block != 0x2C:
			break

		var left = _reader_u16(bytes, cursor)
		var top = _reader_u16(bytes, cursor)
		var width = _reader_u16(bytes, cursor)
		var height = _reader_u16(bytes, cursor)
		var image_packed = _reader_u8(bytes, cursor)
		var palette = global_palette
		if image_packed & 0x80:
			palette = _reader_read(bytes, cursor, (2 << (image_packed & 0x07)) * 3)
		if palette.size() == 0:
			_reader_u8(bytes, cursor)
			_reader_blocks(bytes, cursor)
			continue

		var min_code_size = _reader_u8(bytes, cursor)
		var data = _reader_blocks(bytes, cursor)
		var indices = _decode_lzw(data, min_code_size)
		var before = PoolByteArray()
		if disposal == 3:
			before = _copy_bytes(canvas)
		canvas = _draw_frame(canvas, indices, left, top, width, height,
			palette, transparent_index, image_packed & 0x40,
			scale, out_width, out_height)
		var frame = _image_from_canvas(canvas, out_width, out_height)
		if frame != null:
			frames.append(frame)
			delays.append(delay if delay > 0.0 else DEFAULT_DELAY)
		if disposal == 2:
			canvas = _clear_rect(canvas, left, top, width, height, scale, out_width, out_height)
		elif disposal == 3:
			canvas = before
		disposal = 0
		transparent_index = -1
		delay = DEFAULT_DELAY
		if OS.get_ticks_msec() - started > MAX_DECODE_MS:
			break

	if frames.empty():
		return null
	if frames.size() == 1:
		var texture = ImageTexture.new()
		texture.create_from_image(frames[0], 0)
		return texture
	var animation = AnimatedTexture.new()
	animation.fps = 0.0
	for i in range(frames.size()):
		var texture = ImageTexture.new()
		texture.create_from_image(frames[i], 0)
		animation.set_frame_texture(i, texture)
		animation.set_frame_delay(i, delays[i])
	animation.frames = frames.size()
	animation.oneshot = loop_count == 1
	return animation


static func _copy_bytes(bytes: PoolByteArray) -> PoolByteArray:
	if bytes.size() == 0:
		return PoolByteArray()
	return bytes.subarray(0, bytes.size() - 1)


static func _row_order(height: int, interlaced: bool) -> Array:
	var order = []
	if not interlaced:
		for y in range(height):
			order.append(y)
		return order
	var starts = [0, 4, 2, 1]
	var steps = [8, 8, 4, 2]
	for pass_index in range(4):
		var y = starts[pass_index]
		while y < height:
			order.append(y)
			y += steps[pass_index]
	return order


static func _draw_frame(canvas: PoolByteArray, indices: PoolByteArray, left: int, top: int,
		width: int, height: int, palette: PoolByteArray, transparent_index: int,
		interlaced: int, scale: float, out_width: int, out_height: int) -> PoolByteArray:
	if width <= 0 or height <= 0 or indices.size() < width * height:
		return canvas
	var rows = []
	rows.resize(height)
	var order = _row_order(height, interlaced != 0)
	for i in range(height):
		rows[order[i]] = i
	var colors = _palette_colors(palette)
	var x0 = int(left * scale)
	var y0 = int(top * scale)
	var x1 = int((left + width) * scale + 0.5)
	var y1 = int((top + height) * scale + 0.5)
	if x1 <= x0:
		x1 = x0 + 1
	if y1 <= y0:
		y1 = y0 + 1
	if x0 < 0:
		x0 = 0
	if y0 < 0:
		y0 = 0
	if x1 > out_width:
		x1 = out_width
	if y1 > out_height:
		y1 = out_height
	var inverse = 1.0 / scale
	for dest_y in range(y0, y1):
		var source_y = int((dest_y + 0.5) * inverse - top)
		if source_y < 0:
			source_y = 0
		if source_y >= height:
			source_y = height - 1
		var source_row = rows[source_y] * width
		var dest_row = dest_y * out_width
		for dest_x in range(x0, x1):
			var source_x = int((dest_x + 0.5) * inverse - left)
			if source_x < 0:
				source_x = 0
			if source_x >= width:
				source_x = width - 1
			var index = indices[source_row + source_x]
			if index == transparent_index:
				continue
			var color = index * 4
			if color + 3 >= colors.size():
				continue
			var offset = (dest_row + dest_x) * 4
			canvas[offset] = colors[color]
			canvas[offset + 1] = colors[color + 1]
			canvas[offset + 2] = colors[color + 2]
			canvas[offset + 3] = 255
	return canvas


static func _palette_colors(palette: PoolByteArray) -> PoolByteArray:
	var colors = PoolByteArray()
	var count = int(palette.size() / 3)
	colors.resize(count * 4)
	for i in range(count):
		colors[i * 4] = palette[i * 3]
		colors[i * 4 + 1] = palette[i * 3 + 1]
		colors[i * 4 + 2] = palette[i * 3 + 2]
		colors[i * 4 + 3] = 255
	return colors


static func _clear_rect(canvas: PoolByteArray, left: int, top: int, width: int, height: int,
		scale: float, out_width: int, out_height: int) -> PoolByteArray:
	var x0 = int(left * scale)
	var y0 = int(top * scale)
	var x1 = int((left + width) * scale + 0.5)
	var y1 = int((top + height) * scale + 0.5)
	if x0 < 0:
		x0 = 0
	if y0 < 0:
		y0 = 0
	if x1 > out_width:
		x1 = out_width
	if y1 > out_height:
		y1 = out_height
	for y in range(y0, y1):
		var start = (y * out_width + x0) * 4
		var end = (y * out_width + x1) * 4
		for i in range(start, end):
			canvas[i] = 0
	return canvas


static func _image_from_canvas(canvas: PoolByteArray, width: int, height: int) -> Image:
	var image = Image.new()
	image.create_from_data(width, height, false, Image.FORMAT_RGBA8, _copy_bytes(canvas))
	if image.get_width() == 0:
		return null
	return image


static func _resize_image(image: Image, max_size: int) -> Image:
	var longest = image.get_width()
	if image.get_height() > longest:
		longest = image.get_height()
	if longest <= max_size:
		return image
	var scale = float(max_size) / float(longest)
	var width = int(image.get_width() * scale)
	var height = int(image.get_height() * scale)
	if width < 1:
		width = 1
	if height < 1:
		height = 1
	image.resize(width, height, Image.INTERPOLATE_BILINEAR)
	return image


static func _decode_lzw(data: PoolByteArray, min_code_size: int) -> PoolByteArray:
	var result = PoolByteArray()
	if min_code_size < 1 or min_code_size > 8:
		return result
	var clear_code = 1 << min_code_size
	var end_code = clear_code + 1
	var prefix = PoolIntArray()
	prefix.resize(4096)
	var suffix = PoolByteArray()
	suffix.resize(4096)
	var first = PoolByteArray()
	first.resize(4096)
	for i in range(clear_code):
		first[i] = i

	var stack = PoolByteArray()
	stack.resize(4096)

	var code_size = min_code_size + 1
	var next_code = end_code + 1
	var previous = -1
	var bit_buffer = 0
	var bit_count = 0
	var byte_pos = 0
	var byte_total = data.size()
	var mask = (1 << code_size) - 1

	while true:
		while bit_count < code_size and byte_pos < byte_total:
			bit_buffer |= data[byte_pos] << bit_count
			byte_pos += 1
			bit_count += 8
		if bit_count < code_size:
			break
		var code = bit_buffer & mask
		bit_buffer >>= code_size
		bit_count -= code_size

		if code == clear_code:
			code_size = min_code_size + 1
			mask = (1 << code_size) - 1
			next_code = end_code + 1
			previous = -1
			continue
		if code == end_code:
			break

		var extra = -1
		var chain = code
		if code >= next_code:
			if code != next_code or previous < 0:
				break
			chain = previous
			extra = first[previous]

		var pos = 4096
		if extra >= 0:
			pos -= 1
			stack[pos] = extra
		var valid = true
		while chain >= clear_code:
			if chain >= next_code or pos <= 0:
				valid = false
				break
			pos -= 1
			stack[pos] = suffix[chain]
			chain = prefix[chain]
		if not valid:
			break
		pos -= 1
		stack[pos] = chain
		result.append_array(stack.subarray(pos, 4095))

		if previous >= 0 and next_code < 4096:
			prefix[next_code] = previous
			suffix[next_code] = extra if extra >= 0 else chain
			first[next_code] = first[previous]
			next_code += 1
			if next_code == (1 << code_size) and code_size < 12:
				code_size += 1
				mask = (1 << code_size) - 1
		previous = code
	return result
