# 2D Isometric Camera & Multi-Elevation World

## Approved camera direction

**Cinematic Close-Follow Isometric** mixes:
- Close isometric framing with prominent buildings/streets around the taxi.
- Medium follow framing while driving for situational readability.
- Dense multi-level intersections, bridges and elevated roads.

Use a consistent axonometric projection with **no free camera rotation**, smooth follow, slight look-ahead and authored/contextual zoom-out on bridges and intersections. Interior cutaway scenes use the same projection family but a closer scale. Avoid wide management-game framing.

The supplied 3D-looking city image and the isometric room screenshot are **projection/framing references only**, not commitments to 3D assets or either image's art style.

## 2D runtime rules

Use only 2D sprites, polygons, CanvasItems, UI Controls and 2D drawing. The rendering order must be driven by world coordinates + elevation/occluder metadata; plain Y-sort alone cannot know which connected roadway is above another.

Route graph nodes have stable IDs and coordinate/elevation data. Two roads that overlap on the screen are not necessarily graph-connected. Ramps explicitly connect elevations. Supports, deck edges, shadows and foreground masks are authored visuals.

### First technical gate

Show a taxi:
1. approaching and passing **under** an elevated bridge,
2. continuing and taking an authored ramp **up**,
3. driving across the elevated road **above** the original ground street,
4. maintaining a legible camera and correct occlusion.

The first scene can use placeholder vector art. Its job is proving geometry and presentation, *not* approving final art.

## Passenger overlay

Passenger portrait upper-right; player responses lower-left. Settings toggle `avatar_only` vs `framed` (seat + part of taxi). The presenter is intentionally replaceable; it must not own narrative, relationship or world state.

## Practical compromises

- Fixed view angle makes sprite depth and hand-authored occlusion affordable.
- Multi-elevation is real route topology, not a decorative bridge painted behind the car.
- Authored route modules instead of one seamless open-world city.
- Native 2D art is fine. 3D production is not required or mandated.

Keep the initial renderer simple; do not add custom shaders or massive autotile tooling until a real scene needs them.
