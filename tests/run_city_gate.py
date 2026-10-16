#!/usr/bin/env python3
"""VM/CI gate. GODOT_BIN can point at the pinned 4.7.2 editor."""
import os
import pathlib
import subprocess
import sys

GODOT = os.environ.get("GODOT_BIN", os.environ.get("OD2D_GODOT_BIN", "godot"))
NATIVE = "--native" in sys.argv
OUT = pathlib.Path(os.environ.get("OD2D_LOGS", "/tmp/od2d-gate-logs"))
OUT.mkdir(parents=True, exist_ok=True)
ERRORS = ("SCRIPT ERROR", "ERROR:", "Parse Error", "Failed to load script")

def run(label, args, timeout=90):
    result = subprocess.run([GODOT, "--path", ".", *args], capture_output=True, text=True, timeout=timeout)
    output = result.stdout + result.stderr
    (OUT / (label + ".log")).write_text(output)
    if result.returncode or any(error in output for error in ERRORS):
        print(output)
        raise SystemExit(f"FAIL {label}: see {OUT}")
    if label.startswith("test_") and not any(word in output for word in ("PASS", "passed")):
        raise SystemExit(f"FAIL {label}: no completion marker")
    print("PASS", label, flush=True)

run("import", ["--headless", "--editor", "--import", "--quit"])
for path in sorted(pathlib.Path("tests").glob("test_*.gd")):
    native = path.stem.endswith("_scene") or path.stem in ("test_native_ride", "test_city_presentation")
    if native != NATIVE:
        continue
    args = ["--audio-driver", "Dummy"] if native else ["--headless"]
    run(path.stem, args + ["--script", str(path)])
print("CITY_GATE_PASS", "native" if NATIVE else "domain and adapters")
