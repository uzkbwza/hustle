class_name QuadTree

var boundary: Rect2
var children = null # [0]-[3]: NW, NE, SW, SE
var points = {}
var values = {}
var max_depth
var capacity = 0
var depth

func _init(boundary: Rect2, capacity: int, max_depth: int=0, depth: int=0):
	self.boundary = boundary
	self.max_depth = max_depth
	self.depth = depth
	self.capacity = capacity

func insert(position: Vector2, value = null) -> bool:
	if !contains(position):
		return false
	if children == null and !is_at_capacity():
		if !points.has(position):
			points[position] = [value]
		points[position].append(value)
		return true
	subdivide()
	for child in children:
		if child.insert(position, value):
			return true
	return false

func search_region(region: Rect2, return_values=false, matches=null):
	if matches == null:
		matches = []
	if !overlaps(region):
		return matches
	for point in points.keys():
		if region.has_point(point):
			if return_values: # are we returning the positions or the objects at those positions?
				matches.append_array(points[point])
			else:
				matches.append(point)
	if children:
		for child in children:
			child.search_region(region, return_values, matches)
	return matches

func search(position: Vector2, width: float, height: float, return_values=false, matches=null) -> Array:
	var region = Rect2(position - Vector2(width/2, height/2), Vector2(width, height))
	return search_region(region, return_values, matches)
	
func overlaps(region: Rect2) -> bool:
	return region.intersects(boundary, true)

func contains(position: Vector2) -> bool:
	return boundary.has_point(position)

func is_at_capacity() -> bool:
	return points.size() >= capacity

func subdivide():
	if children == null and (max_depth <= 0 or depth < max_depth):
		children = [
			QuadTree.new(Rect2(boundary.position, boundary.size/2), capacity, max_depth, depth + 1),
			QuadTree.new(Rect2(boundary.position.x + boundary.size.x/2, boundary.position.y, boundary.size.x/2, boundary.size.y/2), capacity, max_depth, depth + 1),
			QuadTree.new(Rect2(boundary.position.x, boundary.position.y + boundary.size.y/2, boundary.size.x/2, boundary.size.y/2), capacity, max_depth, depth + 1),
			QuadTree.new(Rect2(boundary.position.x + boundary.size.x/2, boundary.position.y + boundary.size.y/2, boundary.size.x/2, boundary.size.y/2), capacity, max_depth, depth + 1),
		]
		var point_positions = points.keys()
		for i in range(point_positions.size()):
			var point = point_positions.pop_back()
			var value = points[point]
			points.erase(point)
			for child in children:
				if child.contains(point):
					child.points[point] = value
		return true
	return false
