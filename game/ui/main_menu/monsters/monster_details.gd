extends MenuSection

# temp, for testing
#	var m: Monster = Monster.new({}, preload("res://garden/garden.tscn").instantiate())
#	update(m)

func initialize(key = null):
	title = tr(T.MONSTER_INFO)
	Dispatcher.menu_set_pages.emit(0, 1)
	var m: Monster = U.pick_by(Player.garden.monsters, func(m, _i): return m.uuid == key)
	update(m)

# --------------------------------------------------------------------------- #

func set_section_title(node: Label, t: StringName):
	node.text = str(" ", tr(t).to_upper())

# --------------------------------------------------------------------------- #

func update(m: Monster):
	# name card
	$left/name_card/name.text = m.monster_name
	$left/name_card/sex.update(m)
	$left/name_card/loyalty/hearts.value = m.attributes.loyalty.lerp(0, 10)
	$left/name_card/portrait.update(m)
	
	# species (morph)
	set_section_title($left/info/species/title, T.SPECIES)
	$left/info/species/value.text = str(
		U.trans(m.data.name),
		" (", U.trans(m.data.morphs[m.morph].name), ")"
	)
	
	# attributes summary
	set_section_title($left/info/attributes/title, T.ATTRIBUTES)
	var attrs = $left/info/attributes/panel/grid.get_children()
	for attr in attrs:
		# composite attributes are named in all caps, eg VIT
		var value = m.attributes[attr.name.to_upper()]
		var points = lerp(0, 5, value)
		attr.get_node('points').value = points
	
	set_section_title($left/info/age/title, T.AGE)
	$left/info/age/value.text = str(m.age) # TODO: make this printable
	
	# "traits" section, debug edition: show all attributes' values and their
	# distance from the mean as a multiple of the deviation.  eventually we want
	# to take the most extreme few attributes and translate them into adjectives
	# ("sickly"/"hearty" for vigor, etc).
	# open question: what do we do about attrs whose mean is below the median
	# (because they are meant to accumulate over time, eg vigor's mean is 0.4)?
	var attr_keys = m.attributes.attribute_keys()
	U.sort_by(attr_keys, func(a): return -abs(m.attributes[a].variance))
#	U.sort_by(attr_keys, func(a): return -m.attributes[a].value)
	
	set_section_title($right/traits/title, T.TRAITS)
	$right/traits/panel/scroll/value.horizontal_alignment = HORIZONTAL_ALIGNMENT_FILL
	$right/traits/panel/scroll/value.text = "\n".join(
		attr_keys.map(func(key):
			var attr: Attribute = m.attributes[key]
			return str(
					key, ": ",
					String.num(attr.variance, 1), " ",
					String.num(attr.value, 2),
				)
			)
		) + "\n " # needed to justify the last line
	
	set_section_title($right/birthday/title, T.BIRTHDAY)
	$right/birthday/panel/value.text = Clock.get_printable_time(m.birthday)
