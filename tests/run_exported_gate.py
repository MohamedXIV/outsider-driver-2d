#!/usr/bin/env python3
"""Export and run every Chromium contract at one immutable Git head.

Requires GODOT_BIN (4.7.2), installed Web export templates, Node/Playwright.
OD2D_LOGS selects an ignored output directory; --scope splits independent CI jobs.
The archived prototype differs only in project.godot's main_scene setting.
"""
import argparse
import functools
import hashlib
import http.server
import json
import os
from pathlib import Path
import shutil
import signal
import subprocess
import tarfile
import threading
import time

ROOT = Path(__file__).resolve().parent.parent
os.chdir(ROOT)
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--scope', choices=['all', 'current', 'debug', 'fixture'], default='all')
args = parser.parse_args()
OUT = Path(os.environ.get('OD2D_LOGS', 'work/exported-gate')).resolve()
OUT.mkdir(parents=True, exist_ok=True)
(OUT / '.gdignore').touch()
GODOT = shutil.which(os.environ.get('GODOT_BIN', 'godot'))
assert GODOT, 'Set GODOT_BIN to the pinned Godot 4.7.2 editor'
HEAD = subprocess.check_output(['git', 'rev-parse', 'HEAD'], text=True).strip()
assert not subprocess.check_output(['git', 'status', '--porcelain', '--untracked-files=no']), 'Commit tracked changes before the exact-head gate'
SCOPES = {
    'current': ['web_camera_zoom', 'web_city_playability', 'web_city_routes', 'web_junction_traffic', 'web_two_residents', 'web_passenger_alight'],
    'debug': ['web_sandbox_smoke', 'web_sandbox_routes', 'web_sandbox_reroute', 'web_sandbox_autonomy', 'web_sandbox_peer', 'web_sandbox_driver', 'web_sandbox_meeting', 'web_sandbox_ar'],
    'fixture': ['web_smoke', 'web_ink_smoke', 'web_ride_smoke'],
}
assert {p.stem for p in ROOT.glob('tests/web_*.cjs')} == {p for names in SCOPES.values() for p in names}, 'Unclassified browser suite'
manifest = {'head': HEAD, 'scope': args.scope, 'suites': [], 'exports': {}, 'fixture_override': 'project.godot: main_scene scenes/sandbox.tscn -> scenes/main.tscn'}
manifest_path = OUT / 'manifest.json'

def persist():
    manifest_path.write_text(json.dumps(manifest, indent=2) + '\n')

def run(label, command, cwd=ROOT, env=None, timeout=900):
    start = time.monotonic()
    with (OUT / (label + '.log')).open('w') as log:
        log.write('HEAD ' + HEAD + '\nCOMMAND ' + repr(command) + '\n')
        log.flush()
        process = subprocess.Popen(command, cwd=cwd, env=env, stdout=log, stderr=subprocess.STDOUT, start_new_session=True)
        try:
            code = process.wait(timeout=timeout)
        except subprocess.TimeoutExpired:
            os.killpg(process.pid, signal.SIGTERM)
            try:
                process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                os.killpg(process.pid, signal.SIGKILL)
                process.wait()
            code = 124
    record = {'name': label, 'exit': code, 'seconds': round(time.monotonic()-start, 2)}
    manifest['suites'].append(record)
    persist()
    print(('PASS' if code == 0 else 'FAIL'), label, record['seconds'], flush=True)
    if code != 0:
        print((OUT / (label + '.log')).read_text(), flush=True)
    assert code == 0, f'{label}: see {OUT / (label + ".log")}'
    if label.startswith(('import-', 'export-')):
        output = (OUT / (label + '.log')).read_text()
        assert not any(x in output for x in ['ERROR:', 'SCRIPT ERROR', 'Parse Error', 'Failed to load script']), label

version = subprocess.check_output([GODOT, '--version'], text=True).strip()
assert version.startswith('4.7.2.stable.'), version
manifest['godot'] = version
manifest['node'] = subprocess.check_output(['node', '--version'], text=True).strip()
for directory in ['/tmp/od2d-city-evidence', '/tmp/od2d-ink-evidence', '/tmp/od2d-street-evidence', '/tmp/p0-evidence']:
    shutil.rmtree(directory, ignore_errors=True)
    Path(directory).mkdir(parents=True, exist_ok=True)

class QuietHandler(http.server.SimpleHTTPRequestHandler):
    def log_message(self, *_):
        pass

servers = []
try:
    scopes = list(SCOPES) if args.scope == 'all' else [args.scope]
    exports = {}
    for scope in scopes:
        key = 'fixture' if scope == 'fixture' else 'city'
        if key not in exports:
            project = ROOT
            if key == 'fixture':
                project = OUT / 'fixture-source'
                project.mkdir(exist_ok=True)
                archive = OUT / 'fixture-source.tar'
                subprocess.run(['git', 'archive', '-o', str(archive), HEAD], check=True)
                with tarfile.open(archive) as files:
                    files.extractall(project, filter='data')
                config = project / 'project.godot'
                text = config.read_text()
                assert 'run/main_scene="res://scenes/sandbox.tscn"' in text
                config.write_text(text.replace('run/main_scene="res://scenes/sandbox.tscn"', 'run/main_scene="res://scenes/main.tscn"'))
            target = OUT / (key + '-web')
            target.mkdir(exist_ok=True)
            run('import-' + key, [GODOT, '--headless', '--path', str(project), '--editor', '--import', '--quit'], timeout=240)
            run('export-' + key, [GODOT, '--headless', '--path', str(project), '--export-release', 'Web', str(target / 'index.html')], timeout=240)
            log = (OUT / ('export-' + key + '.log')).read_text()
            assert 'Storing File: res://docs/' not in log and 'Storing File: res://tests/' not in log, 'Non-runtime evidence leaked into export'
            pack = target / 'index.pck'
            manifest['exports'][key] = {'pck_sha256': hashlib.sha256(pack.read_bytes()).hexdigest(), 'bytes': pack.stat().st_size}
            server = http.server.ThreadingHTTPServer(('127.0.0.1', 0), functools.partial(QuietHandler, directory=str(target)))
            threading.Thread(target=server.serve_forever, daemon=True).start()
            servers.append(server)
            exports[key] = f'http://127.0.0.1:{server.server_port}/index.html'
        for name in SCOPES[scope]:
            env = dict(os.environ, OD2D_WEB_URL=exports[key])
            run(name, ['node', str(ROOT / 'tests' / (name + '.cjs'))], env=env)
    assert HEAD == subprocess.check_output(['git', 'rev-parse', 'HEAD'], text=True).strip(), 'Head changed during gate'
    assert not subprocess.check_output(['git', 'status', '--porcelain', '--untracked-files=no']), 'Tracked sources changed during gate'
    manifest['passed'] = True
    print('EXPORTED_GATE_PASS', HEAD, args.scope, flush=True)
finally:
    for server in servers:
        server.shutdown()
    for directory in ['/tmp/od2d-city-evidence', '/tmp/od2d-ink-evidence', '/tmp/od2d-street-evidence', '/tmp/p0-evidence']:
        shutil.copytree(directory, OUT / 'screenshots' / Path(directory).name, dirs_exist_ok=True)
    persist()
