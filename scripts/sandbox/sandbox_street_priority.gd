class_name SandboxStreetPriority
extends RefCounted

# A small local right-of-way rule shared by traffic actors and (later) the
# actual player-taxi adapter. It does not replace Godot collision/navigation.
# Drivers approach a stop line before the marked crossing and resume only
# when the pedestrian is clear of the vehicle lane.
const CROSS_X: float = SandboxStreetModule.CROSS_X
const STOP_DISTANCE: float = 38.0
const CLEAR_AHEAD: float = 40.0
const APPROACH_SPEED: float = 36.0
const LANE_END_X: float = 550.0

static func stop_line() -> float:
	return CROSS_X - STOP_DISTANCE

static func pedestrian_may_enter(vehicle_x: float) -> bool:
	# Vehicles already inside the crossing get to clear it; pedestrians wait.
	return vehicle_x <= stop_line()+4.0 or vehicle_x >= CROSS_X+CLEAR_AHEAD

static func vehicle_velocity(vehicle_x: float, reserved: bool,
		completed: bool, delta: float) -> float:
	if vehicle_x >= LANE_END_X:
		return 0.0
	if reserved and not completed and vehicle_x <= stop_line()+0.05:
		# Clamp distance per physics frame so even a long frame cannot drift
		# into the marked crossing while a resident has committed to crossing.
		return minf(APPROACH_SPEED, maxf(0.0,stop_line()-vehicle_x)/maxf(delta,0.0001))
	if reserved and not completed and vehicle_x <= CROSS_X+CLEAR_AHEAD:
		# This branch is an already occupied crossing: never move back or
		# through a physical walker. Godot's collision remains the safeguard.
		return 0.0
	return APPROACH_SPEED
