extends AnimationPlayer

var current = null
var queue = []
var facing = Vector2(0, 1): set = _update_facing
var loop_counter = 0

func _ready():
	animation_finished.connect(_play_next)

# =========================================================================== #
#                               P L A Y B A C K                               #
# --------------------------------------------------------------------------- #

# calling this will immediately start playing the new anim. currently, this
# leaves the queue intact, so that previously queued animations will resume
# after the current one is over. doesn't matter right now; can change it later
# if necessary.
func play_anim(anim_id = null, loops = null):
	if anim_id: current = anim_id
	if loops: loop_counter = loops
	play(str(current, "/", facing.y, "_", facing.x))

# --------------------------------------------------------------------------- #
func queue_anim(anim_id, loops = 0):
	queue.push_back({"id": anim_id, "loops": loops})
	if current == null: _play_next()

# --------------------------------------------------------------------------- #

# we execute this on our own `animation_finished` signal, which passes the
# finished animation's id. no choice but to accept the argument, even though we
# don't need it.
func _play_next(_old_anim = null):
	if loop_counter - 1 > 0:
		loop_counter = loop_counter - 1
	elif !queue.is_empty():
		var new_anim = queue.pop_front()
		current = new_anim.id
		loop_counter = new_anim.loops
	# else: current = "idle"
	play_anim()

# --------------------------------------------------------------------------- #

# each facing direction is a separate animation, so when our direction changes,
# we need to start playing the animation for the new one. in order to prevent
# it starting over from the beginning, we save our position from the old
# animation and seek to it in the new one.
func _update_facing(new_facing):
	# important because rotation produces values of -0, which throw off our
	# string interpolation (x and y should be either 0 or 1)
	facing = new_facing.abs()
	var anim_pos = current_animation_position
	current_animation = str(current, "/", facing.y, "_", facing.x)
	seek(anim_pos)


# =========================================================================== #
#                         I N I T I A L I Z A T I O N                         #
# --------------------------------------------------------------------------- #

# creates four animations for a given `anim_id` - one in each facing direction
# - which are added to the AnimationPlayer for our sprite.
#
# the resulting animations are identified by a string in "{anim_id}_{y}_{x}"
# format, where y and x are either 0 or 1, and represent the monster's
# front-back and left-right orientation, respectively.
func add_anim(anim_id: String, anim_data: Dictionary):
	var library = AnimationLibrary.new()
	
	var y_dirs = ['back', 'front'] # back = 0, front = 1
	var x_dirs = ['left', 'right'] # left = 0, right = 1
	for y in range(2):
		var y_dir = y_dirs[y]
		var anims: Dictionary = anim_data[y_dir]
		for x in range(2):
			var x_dir = x_dirs[x]
			var anim_name = str(y, "_", x)
			library.add_animation(anim_name,
				_init_facing(anims[x_dir]) if x_dir in anims else
				_init_facing(anims.values()[0], true)
			)
	add_animation_library(anim_id, library)

# --------------------------------------------------------------------------- #

# creates an animation for a specific facing direction, using an `anim_info`
# object from the monster's data definition, and adds it to the AnimationPlayer
# for our sprite.
func _init_facing(anim_info, flip = false):
	# set the step and length parameters of the new animation depending on the
	# frame count and fps specified in the data definition. the `step` parameter
	# will determine the delay between frames when we insert them.
	var anim = Animation.new()
	anim.step = 1.0 / anim_info.fps
	anim.length = anim.step * anim_info.frames
#	anim.loop = anim_info.loop if anim_info.has("loop") else true
	anim.loop_mode = Animation.LOOP_NONE

	# add a track to set our texture to the spritesheet specified in the datafile
	anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(0, "sprite:texture")
	var spritesheet = ResourceLoader.load(anim_info.spritesheet)
	anim.track_insert_key(0, 0.0, spritesheet)

	# add a track to set the hframes value of our texture
	anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(1, "sprite:hframes")
	anim.track_insert_key(1, 0.0, anim_info.frames)

	# add a track to set whether our sprite is h-flipped (for right-facing
	# animations without unique spritesheets).
	# the data definition can optionally also specify whether the sprite should
	# be flipped - in that case, a true value for the `flip` argument will cancel
	# it out (boolean XOR).
	var should_flip = (anim_info.flip != flip
			if anim_info.has("flip") else flip)
	anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(2, "sprite:flip_h")
	anim.track_insert_key(2, 0.0, should_flip)

	# add the animation track, with a keyframe for each frame in the spritesheet
	# at intervals determined by the `step` parameter we calculated earlier
	anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(3, "sprite:frame")
	anim.track_set_interpolation_loop_wrap(2, false)
	for frame in range(anim_info.frames):
		var time = anim.step * frame
		anim.track_insert_key(3, time, frame)
	
	print(anim.get_track_count())
	
	return anim
