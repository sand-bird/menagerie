extends AnimationPlayer

var current: StringName = Monster.Anim.IDLE:
	set(x): 
		var anim = str(x, "/", facing.y, "_", facing.x)
		if !has_animation(anim):
			Log.warn(self, ["animation missing: ", anim])
			return
		current = x
	get: return current
# AnimationPlayer already has a queue
var anim_queue = []
var facing = Vector2i(0, 1): set = _update_facing
var loop_counter = 0

func _ready():
	animation_finished.connect(_play_next)

func _set_current(anim_id: StringName):
	current = anim_id

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
	anim_queue.push_back({"id": anim_id, "loops": loops})
	if current == null: _play_next()

# --------------------------------------------------------------------------- #

# we execute this on our own `animation_finished` signal, which passes the
# finished animation's id. no choice but to accept the argument, even though we
# don't need it.
func _play_next(_old_anim = null):
	if loop_counter - 1 > 0:
		loop_counter = loop_counter - 1
	elif !anim_queue.is_empty():
		var new_anim = anim_queue.pop_front()
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
	
	for y in range(2): for x in range(2):
		library.add_animation(
			str(y, "_", x),
			create_animation_for_facing(
				get_anim_info_for_facing(anim_data, Vector2(x, y))
			)
		)
	add_animation_library(anim_id, library)

# --------------------------------------------------------------------------- #

const y_dirs = ['back', 'front'] # back = 0, front = 1
const x_dirs = ['left', 'right'] # left = 0, right = 1

# given a set of anim data, get the data for a particular facing.
# anim data should always have `front` and `back` keys, and each of these may
# have one or both of `left` and `right` keys.  if the desired horizontal facing
# is not present in the anim data, we use the opposite facing and toggle its
# `flip` property.
func get_anim_info_for_facing(anim_data: Dictionary, raw_facing: Vector2 = facing):
	var _facing = raw_facing.normalized().ceil()
	var y_dir = y_dirs[_facing.y]
	var x_dir = x_dirs[_facing.x]
	var anims: Dictionary = anim_data[y_dir]
	if x_dir in anims: return anims[x_dir]
	var anim = anims.values()[0].duplicate()
	anim.merge({ flip = !anim.get('flip', false) }, true)
	return anim

# --------------------------------------------------------------------------- #

# creates an animation for a specific facing direction, using an `anim_info`
# object from the monster's data definition, and adds it to the AnimationPlayer
# for our sprite.
func create_animation_for_facing(anim_info: Dictionary) -> Animation:
	# set the step and length parameters of the new animation depending on the
	# frame count and fps specified in the data definition. the `step` parameter
	# will determine the delay between frames when we insert them.
	var anim = Animation.new()
	anim.step = 1.0 / anim_info.fps
	anim.length = anim.step * anim_info.frames
#	anim.loop = anim_info.loop if anim_info.has("loop") else true
	anim.loop_mode = Animation.LOOP_NONE
	
	var i: int # current track index
	
	# update the following sprite properties based on anim_info:
	# hframes, flip_h, aux_offset, texture
	i = anim.add_track(Animation.TYPE_METHOD)
	anim.track_set_path(i, "cg/sprite")
	anim.track_insert_key(i, 0.0, {
		method = 'update_texture',
		args = [anim_info]
	})
	
	# add the animation track, with a keyframe for each frame in the spritesheet
	# at intervals determined by the `step` parameter we calculated earlier
	i = anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(i, "cg/sprite:frame")
	anim.track_set_interpolation_loop_wrap(i, false)
	for frame in range(anim_info.frames):
		var time = anim.step * frame
		anim.track_insert_key(i, time, frame)
	
	return anim
