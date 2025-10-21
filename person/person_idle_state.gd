extends AbstractPersonState
class_name IdlePersonState

const name = "IdlePersonState"

var color: Color = Color.GRAY

func process (owner : Person, delta: float):
	var need:= owner.max_need()
	if need.priority > owner.action_threshold:
		owner.satisfyNeedState.need = need
		owner.satisfyNeedState.time_left = need.time_to_satisfy
		var device = UsableDeviceQuery.find_first_device_to_satisfy(need)
		
		#simple moving:
		#owner.movingState.to_state_at_destination = owner.satisfyNeedState
		
		#owner.movingState.destination = device.global_position
		
		#owner.set_state(owner.movingState)
		owner.movingPathState.to_state_at_destination = owner.satisfyNeedState
		var path := zig_zag_path(owner.global_position,device.global_position, 5)
		owner.movingPathState.start_path(path)
		owner.set_state(owner.movingPathState)

		
		
func pp():
	return name
	
# File: path_utils.gd

## Builds a horizontal zig-zag path between start and end.
## The path includes start and end; 'extra_points' are inserted in between.
static func zig_zag_path(start: Vector3, end: Vector3, extra_points: int) -> Array[Vector3]:
	var path: Array[Vector3] = []

	var delta := end - start
	var dist := delta.length()

	# Trivial cases
	if dist < 0.0001 or extra_points <= 0:
		path.append(end)
		return path

	# Forward direction
	var forward := delta / dist

	# Choose a "world up" reference so the zig-zag is horizontal.
	# If movement is nearly vertical, fall back to a forward reference.
	var ref_up := Vector3.UP
	if abs(forward.dot(ref_up)) > 0.99:
		ref_up = Vector3.FORWARD

	# Horizontal axis perpendicular to movement (right/left)
	var right := forward.cross(ref_up).normalized()

	# Even spacing along the segment
	var step := dist / float(extra_points + 1)

	# Lateral amplitude: half a step width (tweak as desired)
	var amplitude := 0.5 * step

	for i in range(1, extra_points + 1):
		var t := float(i) / float(extra_points + 1)
		var base_point := start.lerp(end, t)

		# Alternate sides: +, -, +, - ...
		var side := 1.0
		if (i % 2) == 0:
			side = -1.0

		var offset_point := base_point + right * (amplitude * side)
		path.append(offset_point)

	path.append(end)
	return path
