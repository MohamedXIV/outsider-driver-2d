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
# Center-to-center space between 25px-wide cars leaves 17px clear.
const FOLLOW_SPACING: float = 42.0

static func stop_line() -> float:
	return CROSS_X - STOP_DISTANCE

static func pedestrian_may_enter(vehicle_x: float) -> bool:
	# Vehicles already inside the crossing get to clear it; pedestrians wait.
	return vehicle_x <= stop_line() or vehicle_x >= CROSS_X+CLEAR_AHEAD

static func vehicle_velocity(vehicle_x: float, reserved: bool,
		completed: bool, delta: float) -> float:
	if vehicle_x >= LANE_END_X:
		return 0.0
	if reserved and not completed and vehicle_x <= stop_line():
		# Clamp distance per physics frame so even a long frame cannot drift
		# into the marked crossing while a resident has committed to crossing.
		return minf(APPROACH_SPEED, maxf(0.0,stop_line()-vehicle_x)/maxf(delta,0.0001))
	# A vehicle already beyond the stop line cannot safely yield there.
	# Let it clear the zebra; pedestrian_may_enter() keeps the walker
	# waiting until the vehicle has passed CROSS_X + CLEAR_AHEAD.
	# Stopping this vehicle inside the zebra would deadlock both actors.
	return APPROACH_SPEED

# The leader is moved first in the local street's single physics step. Its
# UPDATED position bounds the follower, without pretending the demo vehicles
# are independently simulated residents of SandboxWorld.
static func follower_velocity(follower_x: float, updated_leader_x: float,
		reserved: bool, completed: bool, delta: float) -> float:
	var gap_velocity: float=maxf(0.0,updated_leader_x-FOLLOW_SPACING-follower_x)/maxf(delta,0.0001)
	return minf(vehicle_velocity(follower_x,reserved,completed,delta),gap_velocity)
