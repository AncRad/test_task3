@tool
class_name Sky3DController
extends Node

enum Weather {Custom, Clear, Rain1, Rain2, Rain3, Snow1, Snow2, Snow3}

@export var weather : Weather = Weather.Custom:
	set(value):
		weather = value
		
		## облака, осадки, туман
		match weather:
			Weather.Clear:
				clear_to_clouds = 0
				precipitation_amount = 0
				fog_strength = 0.2
				fog_dof_amount = 0
			Weather.Rain1, Weather.Snow1:
				clear_to_clouds = 0.5
				precipitation_amount = 0.3
				fog_strength = 0.5
				fog_dof_amount = 0.3
			Weather.Rain2, Weather.Snow2:
				clear_to_clouds = 0.7
				precipitation_amount = 0.7
				fog_strength = 0.7
				fog_dof_amount = 0.3
			Weather.Rain3, Weather.Snow3:
				clear_to_clouds = 0.8
				precipitation_amount = 1
				fog_strength = 1
				fog_dof_amount = 0.5
		
		## снег или дождь
		if weather in [Weather.Rain1, Weather.Rain2, Weather.Rain3]:
			rain_to_snow = 0
		else:
			rain_to_snow = 1
		
		notify_property_list_changed()

## от ястного к тучам
@export_range(0, 1, 0.05)
var clear_to_clouds : float = 0.3:
	set(value):
		clear_to_clouds = value
		queue_update()

## количество осадков
@export_range(0, 1, 0.05)
var precipitation_amount : float:
	set(value):
		precipitation_amount = value
		queue_update()

## количество тумана
@export_range(0, 1, 0.05)
var fog_strength : float:
	set(value):
		fog_strength = value
		queue_update()

## размытие тумана
@export_range(0, 1, 0.05)
var fog_dof_amount : float = 0.5:
	set(value):
		fog_dof_amount = value
		queue_update()


var wind_speed : float:
	set(value):
		if sky:
			sky.wind_speed = value
		queue_update()
	get:
		if sky:
			return sky.wind_speed
		return 0

var wind_direction : float:
	set(value):
		if sky:
			sky.wind_direction = value
		queue_update()
	get:
		if sky:
			return sky.wind_direction
		return 0

var rain_to_snow : float:
	set(value):
		if precipitation_particles:
			precipitation_particles.rain_to_snow = value
		queue_update()
	get:
		if precipitation_particles:
			return precipitation_particles.rain_to_snow
		return 0

var current_time : float:
	set(value):
		if sky:
			sky.current_time = value
		queue_update()
	get:
		if sky:
			return sky.current_time
		return 0

### от дождя к снегопаду
#@export_range(0, 1, 0.01)
#var precipitation_rain_to_snowfall : float = 0

@export_group('inner')
@export var sky : Sky3D:
	set(value):
		sky = value
		notify_property_list_changed()
		queue_update()
@export var camera_manager: Node3D
@export var anim_tree : AnimationTree
@export var precipitation_particles: PrecipitationParticles


var _updating : bool = false


func _get_property_list() -> Array[Dictionary]:
	var list : Array[Dictionary]
	list.append({&'name' : '', &'type' : TYPE_NIL, &'usage' : PROPERTY_USAGE_GROUP})
	if sky:
		for prop : Dictionary in sky.get_property_list():
			if prop.name in [&'current_time', &'wind_speed', &'wind_direction']:
				list.append(prop)
	if precipitation_particles:
		for prop : Dictionary in precipitation_particles.get_property_list():
			if prop.name in [&'rain_to_snow']:
				list.append(prop)
	return list

func _validate_property(property: Dictionary) -> void:
	if property.name in [&'clear_to_clouds', &'precipitation_amount', &'fog_strength', &'fog_dof_amount', &'rain_to_snow']:
		if weather != Weather.Custom:
			property.usage = PROPERTY_USAGE_SCRIPT_VARIABLE | PROPERTY_USAGE_STORAGE

func queue_update() -> void:
	if not _updating:
		_updating = true
		_update.call_deferred()

func _update() -> void:
	if not _updating:
		return
	
	if anim_tree:
		anim_tree[&'parameters/ClearToClouds/blend_position'] = clear_to_clouds
	
	if sky:
		if sky.sky:
			sky.sky.fog_density = remap(fog_strength, 0, 1, 0.0005, 0.01)
	
	if camera_manager:
		var _fog_dof_amount : float = remap(fog_dof_amount, 0, 1, 0, 0.2)
		camera_manager.atmosphere_dof = remap(fog_strength, 0, 1, 0.0, _fog_dof_amount)
	
	if precipitation_particles:
		precipitation_particles.emitting = precipitation_amount > 0
		precipitation_particles.amount_ratio = remap(precipitation_amount, 0, 1, 0.01, 1)
		precipitation_particles.wind_velocity = Vector3.BACK.rotated(Vector3.UP, -wind_direction) * wind_speed
	
	_updating = false
