extends Node

var _throttled_timers = {}  # Stores the last execution time of each throttled function

"""
Throttles a function so it only runs at most every `interval` seconds.
Keeps it's timer based on the "key".

Example usage:
	if Utils.process.callback_throttle("enemy_update", 0.1):
		update_entity("Enemy", 5)
"""
func callback_throttle(key: String, interval: float) -> bool:
	var current_time = Time.get_ticks_msec() / 1000.0  # Get current time in seconds

	if not _throttled_timers.has(key):
		_throttled_timers[key] = 0.0  # Initialize the key

	if current_time - _throttled_timers[key] >= interval:
		_throttled_timers[key] = current_time  # Update last execution time
		return true  # ✅ Allow function to execute

	return false  # ⛔️ Block execution (still within throttle time)
