extends GPUParticles3D
class_name PrecipitationParticles

## скорость верта в глобальной системе координат
@export var wind_velocity : Vector3

## переход от дождя к снегу
@export_range(0, 1, 1)
var rain_to_snow : float:
	set(value):
		rain_to_snow = value


func _process(_delta: float) -> void:
	if process_material is ParticleProcessMaterial:
		var mat : ParticleProcessMaterial = process_material
		
		var wind_speed : float = wind_velocity.length()
		mat.turbulence_noise_strength = remap(wind_speed, 0, 10, 0, 8)
		mat.spread = remap(wind_speed, 0, 10, 0.5, 3)
		if draw_pass_1 is PlaneMesh:
			var plane : PlaneMesh = draw_pass_1
			plane.size.x = remap(rain_to_snow, 0, 1, 0.003, 0.01)
			plane.size.y = remap(rain_to_snow, 0, 1, 0.1, 0.01)
		
		var velocity_vertical : float = -remap(rain_to_snow, 0, 1, 25, 2)
		var velocity : Vector3 = Vector3(0, velocity_vertical, 0) + wind_velocity
		mat.direction = velocity.normalized() * global_basis
		mat.initial_velocity_max = velocity.length()
		mat.initial_velocity_max = velocity.length() + 4
