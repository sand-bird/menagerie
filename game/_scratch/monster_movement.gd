extends KinematicBody2D

var Speed = Constants.Speed

var collider # whatever we're about to hit next
var collision # whatever we've just hit

var destination
var max_speed = Speed.WALK
var max_velocity = max_speed * 2
var current_velocity = Vector2(0, 0)
var arrival_radius = max_velocity / 4
var mass = 100

var points = []
var next_point = 0

func _ready():
	set_physics_process(true)

func _physics_process(delta):
	if destination:
		points = get_path(destination)
		next_point = 1
		seek(points[next_point], delta, next_point + 1 == points.size())
#		if (collision):
#			print("normal: ", collision.normal)
#			print("remainder: ", collision.remainder)
#			print("collider: ", collision.collider, " (", collision.collider_id, ")")
#			print("meta: ", collision.collider_metadata)
		update()
		#for i in points.size():
		#	if i % 2 == 0:
		#		points.remove(i)
		#print("pos: ", position, " | dest: ", destination, " | point: ", points[1])
		#print("next point: ", next_point, " | points: ", points.size())
#		var is_last_point = next_point + 1 == points.size()
#		if !has_reached(points[next_point]):
#			print("seeking point: ", next_point)
#			seek(points[next_point], is_last_point)
#		elif !is_last_point:
#			next_point += 1
#		else:
#			destination = null
#			points = []
#			next_point = 0

func set_dest():
	destination = get_global_mouse_position().floor()
	collision = null
#	points = get_path(destination)
#	next_point = 0

func has_reached(target_pos):
	return position.distance_squared_to(target_pos) < max_speed / 2

func seek(target_pos, delta, do_arrive):
	var distance = position.distance_to(target_pos)
	var target_velocity = (target_pos - position).normalized() * max_velocity
	# print("pos: ", position, " | dist: ", distance)
	
	# ARRIVAL
	if do_arrive and distance < arrival_radius:
		target_velocity = target_velocity * distance / arrival_radius
#		print("tgt: ", target_velocity, "\t| dist: ", distance, "\t| rad: ", arrival_radius)
	
	var steering = (target_velocity - current_velocity).clamped(10)
	current_velocity = (current_velocity + steering).clamped(max_speed)
	$raycast.cast_to = current_velocity.normalized() * 50
	$raycast.enabled = true
	if $raycast.is_colliding() and $raycast.get_collider() != collider:
		collider = $raycast.get_collider()
		print("NEW COLLISION!! ", collider.name)
		var collider_shape = ($raycast.get_collider_shape())
		print(collider_shape)
	# if (is_on_wall()): print("wall")
	
	# current_velocity = target_velocity
	return move_and_slide(current_velocity)
#	update()

# add steering force to velocity
func update_steering():
	pass

func get_path(dest):
	var nav = $"../navigation"
	return nav.get_simple_path(get_global_position(), dest, true)

func _draw():
	if destination:
		draw_circle(destination - get_global_position(), arrival_radius, Color(1, 0.5, 0.5, 0.1))
		draw_circle(destination - get_global_position(), 4, Color(1, 0, 0))
	if points.size() > 0:
		for p in points:
			draw_circle(p - get_global_position(), 2, Color(0, 1, 1))