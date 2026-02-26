@tool
class_name Sky3DController
extends Node

@export
var sky : Sky3D:
	set(value):
		if value != sky:
			sky = value
			notify_property_list_changed()

@export
var anim_tree : AnimationTree

#@export
#var rain : Sky3DRain
#@export
#var show : Sky3DShow

## от ястного к тучам
@export_range(0, 1, 0.001)
var clear_to_clouds : float = 0.3:
	set(value):
		clear_to_clouds = value
		if anim_tree:
			anim_tree[&'parameters/ClearToClouds/blend_position'] = clear_to_clouds
		queue_update()

### количество осадков
#@export_range(0, 1, 0.01)
#var precipitation_size : float = 0
### от дождя к снегопаду
#@export_range(0, 1, 0.01)
#var precipitation_rain_to_snowfall : float = 0

var wind_speed : float:
	set(value):
		if sky:
			sky.wind_speed = value
	get:
		if sky:
			return sky.wind_speed
		return 0
var wind_direction : float:
	set(value):
		if sky:
			sky.wind_direction = value
	get:
		if sky:
			return sky.wind_direction
		return 0

var _updating : bool = false


func _get_property_list() -> Array[Dictionary]:
	var list : Array[Dictionary]
	for prop : Dictionary in sky.get_property_list():
		if prop.name in [&'wind_speed', &'wind_direction']:
			list.append(prop)
	return list


func queue_update() -> void:
	if not _updating:
		_updating = true
		_update.call_deferred()

func _update() -> void:
	if not _updating:
		return
	
	
	
	_updating = false
