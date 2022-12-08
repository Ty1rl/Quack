extends KinematicBody

var sensitivity = 1

var speed = base_speed
const base_speed = 2
const sprint_speed = 4

var jump = 10
var gravity = -20

var direction:Vector3
var velocity_h:Vector3
var velocity_v:Vector3
var snap:Vector3

var rng = RandomNumberGenerator.new()

onready var arm_base = $ArmBase
onready var arm = $ArmBase/SpringArm
onready var camera = $ArmBase/SpringArm/Camera
onready var head = $Head

var step = true
onready var left_foot = $LeftFoot
onready var right_foot = $RightFoot
onready var left_ray = $LeftRay
onready var right_ray = $RightRay
onready var walk_point = $WalkPoint

onready var quack = $Quack
onready var quack_particals = $Head/Bill/QuackParticles

onready var walk_timer = $WalkTimer
onready var walk = $Walk
onready var walk_particals = $WalkParticles

onready var grab_ray = $Head/Bill/GrabRay
onready var grab_point = $Head/Bill/GrabPoint
var grabed_object
var grab_power = 8

var inf_inertia = false
var inertia = 1

func _ready():
	camera.set_physics_interpolation_mode(Node.PHYSICS_INTERPOLATION_MODE_OFF)
	arm.set_as_toplevel(true)
	
	walk_point.set_as_toplevel(true)
	left_foot.set_as_toplevel(true)
	right_foot.set_as_toplevel(true)

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		arm_base.rotate_y(deg2rad(-event.relative.x) * sensitivity)
		arm.rotate_x(deg2rad(event.relative.y) * sensitivity)
		arm.rotation.x = clamp(arm.rotation.x, deg2rad(-70), deg2rad(0))
	
	if Input.is_action_just_pressed("quack"):
		quack.set_pitch_scale(rng.randf_range(0.5,2))
		quack.play()
		quack_particals.set_emitting(true)
	
	if Input.is_action_just_pressed("grab"):
		var collider = grab_ray.get_collider()
		if grabed_object == null and collider != null and collider is RigidBody:
			inf_inertia = true
			grabed_object = collider
			arm.add_excluded_object(collider)
		elif grabed_object != null:
			inf_inertia = false
			arm.remove_excluded_object(grabed_object)
			grabed_object.apply_central_impulse(-arm_base.transform.basis.z * 4)
			grabed_object = null

func _physics_process(delta):
	# horizontal
	direction.z = Input.get_action_strength("move_backward") - Input.get_action_strength("move_forward")
	direction.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	velocity_h = arm_base.transform.basis.xform(direction.normalized() * speed)
	
	# vertical
	if is_on_floor():
		if direction != Vector3.ZERO and walk_timer.is_stopped():
			walk_timer.start()
			walk.set_pitch_scale(rng.randf_range(0.25,1))
			walk.play()
		
		walk_timer.set_wait_time(0.2)
		if Input.is_action_pressed("move_sprint"):
			walk_timer.set_wait_time(0.11)
			if direction != Vector3.ZERO:
				walk_particals.set_emitting(true)
			speed = sprint_speed
		else:
			speed = base_speed
		
		if Input.is_action_just_pressed("move_jump"):
			snap = Vector3.ZERO
			velocity_v.y = jump
		else:
			snap = -get_floor_normal()
			velocity_v.y = 0
	else:
		snap = Vector3.DOWN
		velocity_v.y += gravity * delta
	
	# rotation
	if direction != Vector3.ZERO:
		rotation.y = lerp_angle(rotation.y, atan2(-velocity_h.x, -velocity_h.z), 8 * delta)
		head.rotation.y = Input.get_action_strength("move_left") - Input.get_action_strength("move_right")
	
	arm_base.rotate_y((Input.get_action_strength("look_left") - Input.get_action_strength("look_right"))*sensitivity*2*delta)
	arm.rotate_x((Input.get_action_strength("look_down") - Input.get_action_strength("look_up"))*sensitivity*2*delta)
	arm.rotation.x = clamp(arm.rotation.x, deg2rad(-70), deg2rad(0))
	
	# apply movement
	move_and_slide_with_snap(velocity_h + velocity_v, snap, Vector3.UP, false, 4, 0.785398, inf_inertia)
	for i in get_slide_count():
		var collision = get_slide_collision(i)
		if collision.collider is RigidBody:
			collision.collider.apply_central_impulse(-collision.normal * inertia)
	
	if global_transform.origin.distance_to(walk_point.global_transform.origin) > 0.25:
		walk_point.global_transform.origin = global_transform.origin
		if step:
			if left_ray.is_colliding():
				left_foot.global_transform.origin = left_ray.get_collision_point()
			else:
				left_foot.global_transform.origin = left_ray.global_transform.origin
			step = false
		else:
			if right_ray.is_colliding():
				right_foot.global_transform.origin = right_ray.get_collision_point()
			else:
				right_foot.global_transform.origin = right_ray.global_transform.origin
			step = true
	
	if grabed_object != null:
		var a = grabed_object.get_global_transform_interpolated().origin
		var b = grab_point.get_global_transform_interpolated().origin
		grabed_object.set_linear_velocity((b - a)*grab_power)

func _process(_delta):
	arm.global_transform.origin = arm_base.get_global_transform_interpolated().origin
	arm.rotation.y = arm_base.rotation.y
	arm.rotation.z = 0


func _on_Menu_sensitivity_change(value):
	sensitivity = value
