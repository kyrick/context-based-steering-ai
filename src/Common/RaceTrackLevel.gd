extends Node2D

onready var path = $RaceTrack
onready var path_follow = $RaceTrack/RaceTrackFollow

func get_path_direction(pos):
	var offset = path.curve.get_closest_offset(pos)
	path_follow.offset = offset
	return path_follow.transform.x
