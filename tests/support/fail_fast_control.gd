extends SceneTree

# Negative control for the gate, NOT a real test (it is outside the test_*.gd
# glob). Copy it to tests/test_zz_fail_fast_control.gd to run it through the
# gate. It must FAIL in well under 5 seconds. The `while true` stands in for
# an assert-only test that keeps running after a failure, which the gate must
# not wait out.

func _initialize() -> void:
	if not Check.ok(1 == 2, "deliberate failure for the negative control"):
		return
	while true:
		pass
