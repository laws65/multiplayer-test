extends Resource
class_name GunData


enum GunType {
	AUTOMATIC,
	SEMI,
	BURST,
}

enum ScopeType {
	NONE,
	ZOOM,
	SCAN, # Like aug
}

@export var gun_type: GunType = GunType.AUTOMATIC
@export var scope_type: ScopeType = ScopeType.NONE
@export_range(0, 100) var damage := 15
@export_range(0.0, 1.0, 0.01) var armor_penetration := 0.6 ## Value*damage = damage to enemy
@export_range(0, 100) var damage_falloff := 50 ## drop% over 1000 tiles
@export_range(1, 35, 1, "or_greater") var magazine_size := 30
@export_range(0, 250, 1, "or_greater") var spare_bullets := 120 ## Bullets in reserve
@export_range(1.0, 17.0, 0.1) var fire_rate := 10.0 ## How many times per second the gun shoots
@export_range(50, 250, 1) var run_speed := 200
