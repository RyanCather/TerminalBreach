extends Node3D

@export var enemy_scene: PackedScene
@export var enemy_scene2: PackedScene
@export var spawn_interval: float = 1.0
@export var spawn_radius: float = 100
@export var enemies_per_wave_base: int = 5
@export var wave_increment: int = 2
@export var spawn_points: Array[NodePath] = [] # Add this line!
@onready var Enemies = $CanvasLayer/HUD/Enemies
var current_wave: int = 0
var enemies_to_spawn: int = 0
var enemies_spawned: int = 0
var enemy_scenes := []
var spawn_timer: Timer

func _ready():
	spawn_timer = Timer.new()
	spawn_timer.wait_time = spawn_interval
	spawn_timer.timeout.connect(spawn_enemy)
	spawn_timer.one_shot = false
	enemy_scenes = [enemy_scene, enemy_scene2]
	add_child(spawn_timer)
	var hud = null

	hud = get_tree().get_first_node_in_group("hud")
	if hud:
		print("HUD found:", hud)
		Enemies = hud.get_node_or_null("Enemies")

	start_next_wave()

func start_next_wave():
	current_wave += 1
	enemies_to_spawn = enemies_per_wave_base + wave_increment * (current_wave - 1)
	enemies_spawned = 0
	update_wave_label()
	spawn_timer.start()

func spawn_enemy():
	if enemies_spawned >= enemies_to_spawn:
		spawn_timer.stop()
		return

	var batch_count = min(randi_range(1, 4), enemies_to_spawn - enemies_spawned)
	for i in batch_count:
		# Pick a random spawn point
		var spawn_point_pos = get_random_spawn_point_position()
		# Pick a random enemy scene
		var scene_idx = randi_range(0, enemy_scenes.size() - 1)
		var enemy_instance = enemy_scenes[scene_idx].instantiate()
		enemy_instance.global_transform.origin = spawn_point_pos
		get_tree().current_scene.add_child(enemy_instance)
		enemy_instance.add_to_group("enemy")
		enemies_spawned += 1
		update_wave_label()

	if enemies_spawned >= enemies_to_spawn:
		await monitor_enemies()

func get_random_spawn_point_position() -> Vector3:
	if spawn_points.size() > 0:
		var idx = randi_range(0, spawn_points.size() - 1)
		var node = get_node_or_null(spawn_points[idx])
		if node:
			return node.global_transform.origin
	# fallback: old random position
	var random_dir = Vector3(
		randf_range(-1.0, 1.0),
		0,
		randf_range(-1.0, 1.0)
	).normalized()
	return global_transform.origin + random_dir * randf_range(0.0, spawn_radius)

func monitor_enemies():
	while get_tree().get_nodes_in_group("enemy").size() > 0:
		await get_tree().create_timer(0.5).timeout
	print("Wave", current_wave, "cleared. Starting next wave...")
	await get_tree().create_timer(2.0).timeout
	start_next_wave()

func update_wave_label():
	var alive = get_tree().get_nodes_in_group("enemy").size()
	Enemies.text = "Wave: %d | Enemies: %d" % [current_wave, alive]
