extends ReferenceRect

"""
displays information about a target entity - whoever was last highlighted.
listens to the `entity_highlighted` signal and sets `target` to that entity.
once it has a target, it displays the relevant information and connects to
whatever signals emitted by the target that it needs to keep that information
up to date; all of that logic is handled here.

should persist for a little while when no entity is highlighted, then disappear.
to do this we start an internal timer 
"""

# how long to leave the UI on the screen when nothing is highlighted
const CLEAR_DELAY = 10.0
# how long it takes for it to fade out (included in CLEAR_DELAY)
const FADE_TIME = 1.0

var target: Entity
var time_to_clear = null

# --------------------------------------------------------------------------- #

func _ready():
	Dispatcher.entity_highlighted.connect(_on_highlight)
	Dispatcher.entity_unhighlighted.connect(_on_unhighlight)


func _process(delta):
	$timer.text = str(time_to_clear)
	if time_to_clear != null:
		time_to_clear -= delta
		var alpha = time_to_clear / min(FADE_TIME, CLEAR_DELAY)
		set_modulate(Color(1, 1, 1, alpha))
		if target and time_to_clear <= 0:
			clear_target()


func _on_highlight(entity: Node2D):
	# make sure the entity is valid
	if !entity or not entity is Entity:
		Log.warn(self, ["(_on_highlight) bad entity:", entity])
		return
	# should reset clear state even if it's the same target
	time_to_clear = null
	set_modulate(Color(1, 1, 1, 1))
	# if it's not the same target, swap em out
	if entity and entity != target:
		set_target(entity)


func _on_unhighlight(__):
	time_to_clear = CLEAR_DELAY

# --------------------------------------------------------------------------- #

func set_target(new_target: Node2D):
	# disconnect the existing target if there is one
	if target and target != new_target:
		clear_target()
	# hook up the new target
	target = new_target
	if target is Monster: connect_monster()
	elif target is Item: connect_item()
	elif target is Sessile: connect_object()
	show()

# --------------------------------------------------------------------------- #

# disconnects whatever signals we were listening to on the target.
# 1`get_incoming_connections` returns everything linked to a callable in this
# script, eg `Dispatcher.entity_highlighted`.  we filter those for signals on
# the target, and just disconnect those.
func clear_target(_entity = null):
	hide()
	if !target: return
	Dispatcher.tick_changed.disconnect(update_monster)
	$drives.hide()
	for c in get_incoming_connections():
#		c.signal.disconnect(c.callable)
		if c['signal'].get_object() == target:
			Log.verbose(self, ['(clear_target) found connection to target:', c['signal']])
			c['signal'].disconnect(c['callable'])
	target = null

# --------------------------------------------------------------------------- #

func connect_monster():
	$portrait.update(target, false)
	Dispatcher.tick_changed.connect(update_monster)
	update_monster()

func update_monster():
	var m: Monster = target as Monster
	
	
	$drives.show()
	$name_bar.text = m.get_display_name()
	const bar_length: int = 8
	$drives/container/belly/bar.max_value = bar_length
	$drives/container/belly/bar.value = lerpf(0, bar_length, m.belly / m.belly_capacity)
	$drives/container/belly/current.text = U.str_num(m.belly)
	$drives/container/belly/max.text = U.str_num(m.belly_capacity)
	
	$drives/container/energy/bar.max_value = bar_length
	$drives/container/energy/bar.value = lerpf(0, bar_length, m.energy / m.energy_capacity)
	$drives/container/energy/current.text = U.str_num(m.energy)
	$drives/container/energy/max.text = U.str_num(m.energy_capacity)
	
	$sources/container/scoses/value.text = U.str_num(m.scoses)
	$sources/container/porps/value.text = U.str_num(m.porps)
	$sources/container/fobbles/value.text = U.str_num(m.fobbles)
#	$horizontal.show()
#	$horizontal/belly.value = target.belly
#	$horizontal/energy.value = target.energy
#	$horizontal/social.value = target.social
#	$horizontal/current_action.text = target.current_action.name if target.current_action else 'none'

# --------------------------------------------------------------------------- #

func connect_object():
	$name_bar.text = U.trans(target.data.name)
	$portrait.update(target)
	$horizontal.hide()

func connect_item():
	$name_bar.text = U.trans(target.data.name)
	$portrait.update(target)
	$horizontal.hide()
