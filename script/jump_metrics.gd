class_name JumpMetrics
extends RefCounted

## Trajectory math and platform reachability helpers for level tuning.

const GRAVITY: float = 1150.0
const MIN_VY: float = 240.0
const MAX_VY: float = 680.0
const MIN_VX: float = 95.0
const MAX_VX: float = 230.0
const MAX_CHARGE_TIME: float = 0.60
const CHARGE_STAGES: int = 36


static func get_launch_vy(charge_stage: int) -> float:
	var alpha: float = clampf(float(charge_stage) / float(CHARGE_STAGES), 0.0, 1.0)
	return lerpf(MIN_VY, MAX_VY, alpha)


static func get_launch_vx(charge_stage: int) -> float:
	var alpha: float = clampf(float(charge_stage) / float(CHARGE_STAGES), 0.0, 1.0)
	return lerpf(MIN_VX, MAX_VX, alpha)


static func get_apex_height(charge_stage: int) -> float:
	var vy: float = get_launch_vy(charge_stage)
	return (vy * vy) / (2.0 * GRAVITY)


static func get_time_to_apex(charge_stage: int) -> float:
	var vy: float = get_launch_vy(charge_stage)
	return vy / GRAVITY


static func get_jump_distance(charge_stage: int) -> float:
	var total_time: float = 2.0 * get_time_to_apex(charge_stage)
	var vx: float = get_launch_vx(charge_stage)
	return vx * total_time


# Returns true if (dx, dy) is within the max jump reach envelope
static func is_platform_reachable(dx: float, dy: float) -> bool:
	var max_apex: float = get_apex_height(CHARGE_STAGES)
	if -dy > max_apex:
		return false

	var max_distance: float = get_jump_distance(CHARGE_STAGES) * 1.25
	if absf(dx) > max_distance:
		return false

	return true
