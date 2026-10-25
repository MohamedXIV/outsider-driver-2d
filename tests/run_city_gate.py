#!/usr/bin/env python3
"""VM/CI gate. GODOT_BIN can point at the pinned 4.7.2 editor."""
import os
import pathlib
import subprocess
import sys
import time

GODOT = os.environ.get("GODOT_BIN", os.environ.get("OD2D_GODOT_BIN", "godot"))
NATIVE = "--native" in sys.argv
OUT = pathlib.Path(os.environ.get("OD2D_LOGS", "/tmp/od2d-gate-logs"))
# OD2D_ONLY=test_stem runs a single test file (used for the fail-fast negative control).
ONLY = os.environ.get("OD2D_ONLY", "")
OUT.mkdir(parents=True, exist_ok=True)
ERRORS = ("SCRIPT ERROR", "ERROR:", "Parse Error", "Failed to load script")
version = subprocess.check_output([GODOT, "--version"], text=True).strip()
if not version.startswith("4.7.2.stable."):
    raise SystemExit(f"Use Godot 4.7.2, got {version}")
head = subprocess.check_output(["git", "rev-parse", "HEAD"], text=True).strip()
if subprocess.check_output(["git", "status", "--porcelain", "--untracked-files=no"]):
    raise SystemExit("Commit tracked changes before the exact-head gate")
print("HEAD", head, "GODOT", version, flush=True)
(OUT / "head.txt").write_text(head + "\n" + version + "\n")

def run(label, args, timeout=90):
    # Stream output into the log while the test runs. A "FAIL " line from
    # tests/support/check.gd means the test has already decided: kill it now
    # instead of waiting for the timeout backstop.
    log_path = OUT / (label + ".log")
    deadline = time.monotonic() + timeout
    with log_path.open("w") as log:
        process = subprocess.Popen([GODOT, "--path", ".", *args], stdout=log, stderr=subprocess.STDOUT)
        while True:
            text = log_path.read_text(errors="replace")
            failed = [line for line in text.splitlines() if line.startswith("FAIL ")]
            if failed or any(error in text for error in ERRORS):
                process.kill()
                process.wait()
                print(text[-4000:])
                raise SystemExit(f"FAIL {label}: {(failed or ['error marker'])[0]} (killed early; log in {OUT})")
            if process.poll() is not None:
                break
            if time.monotonic() > deadline:
                process.kill()
                process.wait()
                raise SystemExit(f"FAIL {label}: timeout; partial output retained in {OUT}")
            time.sleep(0.05)
    output = log_path.read_text(errors="replace")
    if process.returncode:
        print(output[-4000:])
        raise SystemExit(f"FAIL {label}: exit code {process.returncode}; see {OUT}")
    if label.startswith("test_") and not any(word in output for word in ("PASS", "passed")):
        raise SystemExit(f"FAIL {label}: no completion marker")
    print("PASS", label, flush=True)

run("import", ["--headless", "--editor", "--import", "--quit"])
for path in sorted(pathlib.Path("tests").glob("test_*.gd")):
    native = path.stem.endswith("_scene") or path.stem in ("test_native_ride", "test_city_presentation", "test_world_shuttle_visual")
    if native != NATIVE or (ONLY and path.stem != ONLY):
        continue
    args = ["--audio-driver", "Dummy"] if native else ["--headless"]
    run(path.stem, args + ["--script", str(path)])
assert head == subprocess.check_output(["git", "rev-parse", "HEAD"], text=True).strip(), "Head changed during gate"
assert not subprocess.check_output(["git", "status", "--porcelain", "--untracked-files=no"]), "Tracked sources changed during gate"
print("CITY_GATE_PASS", "native" if NATIVE else "domain and adapters", head)
