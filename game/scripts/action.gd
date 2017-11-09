# class Action

extends Node

var target
var duration
var duration_remaining

func _init(tar, dur):
	self.target = tar
	self.duration = dur
	self.duration_remaining = dur

func _ready():
	pass