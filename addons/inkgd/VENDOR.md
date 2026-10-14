# Vendored Ink runtime: inkgd

Upstream: https://github.com/ephread/inkgd (branch `godot4`, pinned commit `fea9098ee18d6cdbe9a5e25f8f0296bcdf0fd96a`).
License: MIT (see `LICENSE`).

Vendored unmodified GDScript **runtime-only** subset. No C#, editor plugin or Inochi2D. Application code interacts only via `scripts/narrative/ink_bridge.gd`. Authored Ink text is compiled to JSON bytecode before release.
