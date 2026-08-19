extends PointLight2D

## Master scale multiplier for the light's texture scale
@export var overall_scale: float = 1.0

@export_group("Energy Settings")
@export var base_energy: float = 1.0
@export var energy_flicker_range: float = 0.35 # Intensity fluctuation (+/-)

@export_group("Scale Settings")
@export var scale_flicker_range: float = 0.15  # Size fluctuation (+/-)

@export_group("Flicker Speed")
@export var flicker_speed: float = 20.0

var _noise: FastNoiseLite = FastNoiseLite.new()
var _time: float = 0.0

func _ready() -> void:
	# Configure noise generator for natural flame flickering
	_noise.seed = randi()
	_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	_noise.frequency = 0.1

func _process(delta: float) -> void:
	_time += delta * flicker_speed

	# Sample noise (returns values from -1.0 to 1.0)
	var energy_noise = _noise.get_noise_1d(_time)
	var scale_noise = _noise.get_noise_1d(_time + 1000.0) # Offset seed for variation

	# Update energy
	energy = base_energy + (energy_noise * energy_flicker_range)

	# Update texture scale combining noise variation with overall_scale
	var flicker_scale_offset = 1.0 + (scale_noise * scale_flicker_range)
	texture_scale = overall_scale * flicker_scale_offset
