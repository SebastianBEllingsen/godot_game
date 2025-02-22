extends CharacterBody3D

var speed
const WALK_SPEED = 5.0
const SPRINT_SPEED = 8.0
const JUMP_VELOCITY = 4.5
var gravity=9.8
var sensitivity = 0.005
var t_bob = 0.0

const BOB_FREQ = 2.0
const BOB_AMP = 0.05
const BASE_FOV = 75.0
const FOV_CHANGE = 1.5


@onready var head = $head
@onready var camera = $head/Camera3D
@onready var anim_player= $AnimationPlayer
@onready var view_check = $"../TextureRect"

var show_cam=false

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	view_check.visible = false
func _unhandled_input(event):
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * sensitivity)
		camera.rotate_x(-event.relative.y * sensitivity)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-70), deg_to_rad(90))

func _input(event):
	if Input.is_action_just_pressed("cam"):
		view_check.visible = !view_check.visible

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	if Input.is_action_pressed("leftshift"):
		speed = SPRINT_SPEED
		var velocity_clamped = clamp(velocity.length(), 0.5, SPRINT_SPEED *2)
		var target_fov = BASE_FOV + FOV_CHANGE * velocity_clamped
		camera.fov = lerp(camera.fov, target_fov, delta * 8.0)
	else:
		speed = WALK_SPEED
		var velocity_clamped = clamp(velocity.length(), 0.5, SPRINT_SPEED *2)
		var target_fov = BASE_FOV - FOV_CHANGE * velocity_clamped
		camera.fov = lerp(camera.fov, target_fov, delta * 2.0)
	#Input and movement
	var input_dir := Input.get_vector("left", "right", "foward", "back")
	var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if is_on_floor():
		if direction:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			velocity.x = lerp(velocity.x, direction.x * speed, delta * 8.0)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * 8.0)
	else:
		velocity.x = lerp(velocity.x, direction.x * speed, delta * 1.0)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * 1.0)
	
	t_bob += delta* velocity.length() * float(is_on_floor())
	camera.transform.origin = headbob(t_bob)
	
	#FOV enables when walking normally, fix this

	move_and_slide()

func _process(delta):
	if Input.is_action_pressed("kick"):
		$head/Camera3D/foot/Area3D/MeshInstance3D.visible = true
		anim_player.play("kick")

func headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQ) * BOB_AMP
	pos.x = cos(time * BOB_FREQ / 2) * BOB_AMP
	return pos


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "kick":
		$head/Camera3D/foot/Area3D/MeshInstance3D.hide
