class_name SandboxVehicleKinematics
extends RefCounted

# Kinematics only for LOCAL Godot bodies and taxi's on-screen heading.
# This module must not own travel minutes, car identity or fare settlement.
const CRUISE: float = 36.0
const ACCELERATION: float = 48.0  # local street units per second²
const SERVICE_BRAKE: float = 96.0
const TURN_RATE: float = 2.2     # rad/s visual yaw cap

static func next_speed(current: float, target: float, delta: float) -> float:
	if not is_finite(current) or not is_finite(target) or not is_finite(delta): return 0.0
	if delta <= 0.0: return clampf(current,0.0,CRUISE)
	var safe_current: float=clampf(current,0.0,CRUISE)
	var safe_target: float=clampf(target,0.0,CRUISE)
	var max_change: float=(ACCELERATION if safe_target>safe_current else SERVICE_BRAKE)*delta
	return move_toward(safe_current,safe_target,max_change)

static func braking_speed(distance: float) -> float:
	if not is_finite(distance) or distance<=0.0: return 0.0
	return minf(CRUISE,sqrt(2.0*SERVICE_BRAKE*distance))

static func turn_heading(current: float, desired: float, delta: float) -> float:
	if not is_finite(current) or not is_finite(desired) or not is_finite(delta): return current
	if delta<=0.0: return current
	return wrapf(current+clampf(angle_difference(current,desired),
			-TURN_RATE*delta,TURN_RATE*delta),-PI,PI)
