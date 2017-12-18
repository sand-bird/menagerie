extends Node

# --------------
# CAMERA OPTIONS
# --------------

var drag_scroll_enabled = true
var edge_scroll_enabled = true

# options used for drag scroll
var camera_flick_distance = 8.0
var camera_flick_speed = 0.7

# options used for edge scroll
var camera_edge_size = 0.05 # percent of total screen width/height
var camera_scroll_speed = 0.30
var camera_scroll_acceleration = 1.05 # increases asymptotically toward 1.0

func is_drag_scroll_enabled(): return drag_scroll_enabled
func set_drag_scroll_enabled(val): drag_scroll_enabled = val

func is_edge_scroll_enabled(): return edge_scroll_enabled
func set_edge_scroll_enabled(val): edge_scroll_enabled = val