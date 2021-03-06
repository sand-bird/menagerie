################################################################################
#The MIT License (MIT)
#=====================
#
#Copyright (c) 2019 Tom "Butch" Wesley
#
#Permission is hereby granted, free of charge, to any person obtaining a copy
#of this software and associated documentation files (the "Software"), to deal
#in the Software without restriction, including without limitation the rights
#to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#copies of the Software, and to permit persons to whom the Software is
#furnished to do so, subject to the following conditions:
#
#The above copyright notice and this permission notice shall be included in
#all copies or substantial portions of the Software.
#
#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
#THE SOFTWARE.
#
################################################################################

################################################################################
# This class contains all the GUI creation code for Gut.  It was split out and
# hopefully can be moved to a scene in the future.
################################################################################
extends Control

# various counters.  Most have been moved to the Summary object but not all.
var _summary = {
	moved_methods = 0,
	# these are used to display the tally in the top right corner.  Since the
	# implementation changed to summing things up at the end, the running
	# update wasn't showing.  Hack.
	tally_passed = 0,
	tally_failed = 0
}

var _is_running = false
var title_offset = Vector2(0, get_constant("title_height"))

var _mouse_down = false
var _mouse_down_pos = null
var _mouse_in = false

func _set_anchor_top_right(obj):
	obj.set_anchor(MARGIN_RIGHT, ANCHOR_BEGIN)
	obj.set_anchor(MARGIN_LEFT, ANCHOR_END)
	obj.set_anchor(MARGIN_TOP, ANCHOR_BEGIN)

func _set_anchor_bottom_right(obj):
	obj.set_anchor(MARGIN_LEFT, ANCHOR_END)
	obj.set_anchor(MARGIN_RIGHT, ANCHOR_END)
	obj.set_anchor(MARGIN_TOP, ANCHOR_END)
	obj.set_anchor(MARGIN_BOTTOM, ANCHOR_END)

func _set_anchor_bottom_left(obj):
	obj.set_anchor(MARGIN_LEFT, ANCHOR_BEGIN)
	obj.set_anchor(MARGIN_TOP, ANCHOR_END)
	obj.set_anchor(MARGIN_TOP, ANCHOR_END)

#-------------------------------------------------------------------------------
# Adds all controls to the window, sizes and poisitions them.
#-------------------------------------------------------------------------------
func setup_controls():
	var button_size = Vector2(75, 35)
	var button_spacing = Vector2(10, 0)
	var pos = Vector2(0, 0)

	var log_label = Label.new()
	add_child(log_label)
	log_label.set_text("Log Level")
	log_label.set_position(Vector2(10, $text_box.get_size().y + 1))
	_set_anchor_bottom_left(log_label)

	$log_level_slider.set_size(Vector2(75, 30))
	$log_level_slider.set_position(Vector2(10, log_label.get_position().y + 20))
	$log_level_slider.set_min(0)
	$log_level_slider.set_max(2)
	$log_level_slider.set_ticks(3)
	$log_level_slider.set_ticks_on_borders(true)
	$log_level_slider.set_step(1)
	_set_anchor_bottom_left($log_level_slider)

	var script_prog_label = Label.new()
	add_child(script_prog_label)
	script_prog_label.set_position(Vector2(100, log_label.get_position().y))
	script_prog_label.set_text('Scripts:')
	_set_anchor_bottom_left(script_prog_label)

	$script_progress.set_size(Vector2(200, 10))
	$script_progress.set_position(script_prog_label.get_position() + Vector2(70, 0))
	$script_progress.set_min(0)
	$script_progress.set_max(1)
	$script_progress.set_step(1)
	_set_anchor_bottom_left($script_progress)

	var test_prog_label = Label.new()
	add_child(test_prog_label)
	test_prog_label.set_position(Vector2(100, log_label.get_position().y + 15))
	test_prog_label.set_text('Tests:')
	_set_anchor_bottom_left(test_prog_label)

	$test_progress.set_size(Vector2(200, 10))
	$test_progress.set_position(test_prog_label.get_position() + Vector2(70, 0))
	$test_progress.set_min(0)
	$test_progress.set_max(1)
	$test_progress.set_step(1)
	_set_anchor_bottom_left($test_progress)

	$previous_button.set_size(Vector2(50, 25))
	pos = $test_progress.get_position() + Vector2(250, 25)
	pos.x -= 300
	$previous_button.set_position(pos)
	$previous_button.set_text("<")
	_set_anchor_bottom_left($previous_button)

	$stop_button.set_size(Vector2(50, 25))
	pos.x += 60
	$stop_button.set_position(pos)
	$stop_button.set_text('stop')
	_set_anchor_bottom_left($stop_button)

	$run_rest.set_text('run')
	$run_rest.set_size(Vector2(50, 25))
	pos.x += 60
	$run_rest.set_position(pos)
	_set_anchor_bottom_left($run_rest)

	$next_button.set_size(Vector2(50, 25))
	pos.x += 60
	$next_button.set_position(pos)
	$next_button.set_text(">")
	_set_anchor_bottom_left($next_button)

	$runtime_label.set_text('0.0')
	$runtime_label.set_size(Vector2(50, 30))
	$runtime_label.set_position(Vector2($clear_button.get_position().x - 90, $next_button.get_position().y))
	_set_anchor_bottom_right($runtime_label)

	# the drop down has to be one of the last added so that when then list of
	# scripts is displayed, other controls do not get in the way of selecting
	# an item in the list.
	$scripts_drop_down.set_size(Vector2(375, 25))
	$scripts_drop_down.set_position(Vector2(10, $log_level_slider.get_position().y + 50))
	_set_anchor_bottom_left($scripts_drop_down)
	$scripts_drop_down.set_clip_text(true)

	$run_button.set_text('<- run')
	$run_button.set_size(Vector2(50, 25))
	$run_button.set_position($scripts_drop_down.get_position() + Vector2($scripts_drop_down.get_size().x + 5, 0))
	_set_anchor_bottom_left($run_button)

func set_it_up():
	setup_controls()
	self.connect("mouse_entered", self, "_on_mouse_enter")
	self.connect("mouse_exited", self, "_on_mouse_exit")
	set_process(true)
	set_pause_mode(PAUSE_MODE_PROCESS)
	_update_controls()

#-------------------------------------------------------------------------------
# Updates the display
#-------------------------------------------------------------------------------
func _update_controls():

	if(_is_running):
		$previous_button.set_disabled(true)
		$next_button.set_disabled(true)
		$pass_count.show()
	else:
		$previous_button.set_disabled($scripts_drop_down.get_selected() <= 0)
		$next_button.set_disabled($scripts_drop_down.get_selected() != -1 and $scripts_drop_down.get_selected() == $scripts_drop_down.get_item_count() -1)
		$pass_count.hide()

	# disabled during run
	$run_button.set_disabled(_is_running)
	$run_rest.set_disabled(_is_running)
	$scripts_drop_down.set_disabled(_is_running)

	# enabled during run
	$stop_button.set_disabled(!_is_running)
	$pass_count.set_text(str( _summary.tally_passed, ' - ', _summary.tally_failed))


#-------------------------------------------------------------------------------
# detect mouse movement
#-------------------------------------------------------------------------------
func _on_mouse_enter():
	_mouse_in = true

#-------------------------------------------------------------------------------
# detect mouse movement
#-------------------------------------------------------------------------------
func _on_mouse_exit():
	_mouse_in = false
	_mouse_down = false


#-------------------------------------------------------------------------------
# Send text box text to clipboard
#-------------------------------------------------------------------------------
func _copy_button_pressed():
	$text_box.select_all()
	$text_box.copy()


#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
func _init_run():
	$text_box.clear_colors()
	$text_box.add_keyword_color("PASSED", Color(0, 1, 0))
	$text_box.add_keyword_color("FAILED", Color(1, 0, 0))
	$text_box.add_color_region('/#', '#/', Color(.9, .6, 0))
	$text_box.add_color_region('/-', '-/', Color(1, 1, 0))
	$text_box.add_color_region('/*', '*/', Color(.5, .5, 1))
	$runtime_label.set_text('0.0')
	$test_progress.set_max(1)

#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
func _input(event):
	# if the mouse is somewhere within the debug window
	if(_mouse_in):
		# Check for mouse click inside the resize handle
		if(event is InputEventMouseButton):
			if (event.button_index == 1):
				# It's checking a square area for the bottom right corner, but that's close enough.  I'm lazy
				if(event.position.x > get_size().x + get_position().x - 10 and event.position.y > get_size().y + get_position().y - 10):
					if event.pressed:
						_mouse_down = true
						_mouse_down_pos = event.position
					else:
						_mouse_down = false
		# Reszie
		if(event is InputEventMouseMotion):
			if(_mouse_down):
				var new_size = get_size() + event.position - _mouse_down_pos
				var new_mouse_down_pos = event.position

				_mouse_down_pos = new_mouse_down_pos
				set_size(new_size)

#-------------------------------------------------------------------------------
#Custom drawing to indicate results.
#-------------------------------------------------------------------------------
func _draw():
	# Draw the lines in the corner to show where you can
	# drag to resize the dialog
	var grab_margin = 2
	var line_space = 3
	var grab_line_color = Color(.4, .4, .4)
	for i in range(1, 6):
		draw_line(get_size() - Vector2(i * line_space, grab_margin), get_size() - Vector2(grab_margin, i * line_space), grab_line_color)
