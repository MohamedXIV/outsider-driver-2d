# Outsider Driver — Playability Feedback Register

> **Living human-feedback register / first entry October 16, 2026.** [Central discussion & workstream board: #48](https://github.com/MohamedXIV/outsider-driver-2d/issues/48). [Execution roadmap](SANDBOX_EXECUTION_ROADMAP.md). This is a product feedback record, NOT a QA pass, sprint calendar or duplicate implementation backlog.

## Baseline: what is actually known

- **Gameplay:** Godot 4.x 2D / axonometric sandbox driven by one authoritative `SandboxWorld`; systemic nine-NPC sample, real Ink conversations, priced translator/AR equipment, physical store, seeded fare dispatch, road graph routes, reroute and persistent social encounters. [Last verified baseline before this feedback](https://github.com/MohamedXIV/outsider-driver-2d/commit/4c9c848b467baa4a1bcb4b30c35f31504db62936).
- **Visuals:** `SandboxRoads` presently has **five district nodes** linked by a simple graph; `SandboxCityView` draws **straight lines** between district projections and interpolates taxi motion linearly. This is a schematic playable engineering sample, *not* evidence of a real-scale, physically rich city or believable bridges.
- **Human feedback:** user reports information overload / confusing debug text, rushed and fragmented trip experience, and wants naturally larger urban distances, engaging UI and curved/elevated natural-looking roads.
- **Checklist baseline (R01):** the user explicitly answered **False to all four playability questions for the CURRENT debug dashboard**, and cautioned that applying that checklist here is **misleading** because the required Player Mode / world presentation does not exist yet. Treat this as **4/4 presently unmet in the prototype**, **not** an isolated assessment of the finished design or four independent root causes. Detailed scenario-by-scenario feedback, numerical pacing score, artistic reference and user approval of a revised Player Mode/large city/splines are NOT provided. Do not invent these. Green native/Web checks prove functional gameplay invariants, **not** human comfort or appearance. Windows release export is not actual Windows runtime.

## Long-lived observations (IDs never recycled)

| ID | Original observation / direction | Owner issue | Priority | Current status | Technical proof | Human acceptance |
|---|---|---|---|---|---|---|
| **FB-001** | Trips feel too short and pressuring to notice passenger, read/talk, enjoy road scenery. **Approved correction:** a sufficiently large and varied city should naturally give rides breathing room, rather than fake time dilation. | [#51](https://github.com/MohamedXIV/outsider-driver-2d/issues/51) | High | **Accepted direction — not implemented** | None after this feedback | **Pending** |
| **FB-002** | Existing on-screen diagnostic texts cause confusion and compete with playing. **Approved:** default Player Mode + explicit reversible Debug Mode for developer telemetry. | [#49](https://github.com/MohamedXIV/outsider-driver-2d/issues/49) | First slice | **Accepted direction — not implemented** | None after this feedback | **Pending** |
| **FB-003** | Roads should look organic: splines/curves, real-feeling bridges, flyovers and sensible elevation instead of toy straight lines. | [#52](https://github.com/MohamedXIV/outsider-driver-2d/issues/52) | High, coordinated with #51 | **Accepted direction — not implemented** | None after this feedback | **Pending** |
| **FB-004** | Player HUD should be attractive, intuitive, supportive and readable, rather than merely debug controls with colors. | [#50](https://github.com/MohamedXIV/outsider-driver-2d/issues/50) | High, builds on #49 | **Accepted direction — not implemented** | None after this feedback | **Pending** |

**Checklist correction:** The user has now given a **pre-reboot baseline verdict of False on all four questions**, while explicitly stating that scoring a debug-world/dashboard as a game is misleading. This is captured in **R01**, not treated as four independent gameplay defects, and is **not a verdict on a not-yet-existing Player Mode**. More detailed scenario-based notes remain optional/pending. **Do not prompt repeatedly, invent responses, schedule mandatory check-ins or mark a category approved by the user beyond the directions actually stated.**

## Lightweight recurring review protocol — trigger on feedback or a new playable build

This is a workflow triggered by actual iterative gameplay/builds, **not** a background automation:

1. **Intake:** User comment / screenshot / recording → append a dated entry under "Feedback rounds" with platform, build or SHA, seed and reproduction only when available. Unknown fields = `Not provided`.
2. **Classify:** associate an existing FB ID (or a new one), issue, perceived pain and severity if **reported**. Distinguish the user's own observation from the developer's explanation/hypothesis.
3. **Decide:** preserve original note, record accepted response `Do now / Later / Not planned` with reason and dependencies; re-rank a single authoritative board (#48 + child issues).
4. **Implement:** each PR records `FB-ID`, before→after, what was changed, exact acceptance scenarios, verified local/native/Web evidence with run and branch heads. Do not create unrelated major systems or run GitHub Actions for docs-only updates.
5. **Hand back:** move item to `Implemented (technical) / Ready for human check` after green code tests. Provide a concise tailored request to try **one or two relevant interactions**; do not dump another long checklist unless user asks.
6. **Review:** next real user impression records `Human accepted`, `Needs rework`, or `Unassessed`. If rework, edit the same issue / append the next round without erasing what previously shipped or passed. Summarize `Changed / Still painful / Next targeted experiment` in #48 and this register.

### Status semantics

`Reported` → `Accepted direction` → `In progress` → `Implemented (technical)` → `Ready for human check` → **either** `Human accepted` or `Needs rework`. `Deferred` and `Not planned` require an explanation; automated CI passing must **never** substitute for `Human accepted`.

### Entry format (copy for each new actual round)

```markdown
### Feedback round Rxx — <date> — build / SHA <if known>
- Environment / platform / viewport / seed: <reported or Not provided>
- User's own observation: <verbatim or attributed paraphrase>
- FB IDs / linked issue(s): #...
- Hypothesis (developer, explicitly an interpretation): ...
- Decision / change made (PR, commit): ... / Not implemented
- Technical evidence (native, Web, screenshot): ... / Not tested
- User re-test / verdict: Human accepted / Needs rework / Pending
- Remaining discomfort and next narrowly scoped experiment: ...
```

## Feedback rounds

### R00 — October 16, 2026 — initial perception
- **Environment:** user has begun checking the game; build/OS/seed/duration not specified in the feedback.
- **User observations:** overwhelmed by debug writings; journeys feel rushed/short for watching NPC/world and conversing; wishes visually natural roads, splines, bridges, flyovers, and attractive intuitive UI.
- **Approved refinements:** Player Mode default vs Debug Mode; a city large enough to create natural journey breathing room rather than arbitrary delay; track changes and feedback consistently.
- **Work registered:** #48 overarching, #49 mode separation, #50 player UI improvement, #51 city/ride scale and pacing, #52 road geometry/elevation.
- **Implementation of these changes:** Not started. The existing verified sim and renders are merely technical baseline.
- **Human verdict on revised build:** **Pending**; no revised build submitted. See R01 for the user's subsequently supplied *current debug-build* baseline of four False responses.
- **Next action:** implement #49 as the first independently playable slice; coordinate #51/#52 topology and track one real passenger ride and world/route visibility. Wait for user-provided checklist whenever they choose to send it.

### R01 — October 16, 2026 — user's four-point checklist baseline correction
- **Source / exact user distinction:** «الاجابة عن الـ 4 نقاط الـ Checklist هيكون مش مظبوط ومضلل لان الموجود الان debug world/dashboard لذلك الاربع نقاط الاجابة عليهم false».
- **Environment / build:** Existing debug world/dashboard; exact OS, viewport, runtime, seed and SHA of the session were **not provided**.
- **Checklist (as asked of the existing debug dashboard):**

  | Check from assistant's previous four-point list | User's answer | Interpretation |
  |---|---|---|
  | **1. Ride comfort:** enough time to observe and understand rather than feel rushed | **False** | Current debug travel gives no comfortable ride feel; the systemic city's eventual pacing is **not separately assessed**. |
  | **2. UI clarity:** know what to do without a wall of text | **False** | Dashboard-first UX fails as a game-facing interface; no Player Mode build exists yet. |
  | **3. City believability:** roads and movement evoke a convincing city | **False** | Current schematic five-node straight-line roads are not representative of intended city visuals. |
  | **4. In-ride dialogue comfort:** read and follow passenger exchanges without stress/confusion | **False** | Debug-stage dialogue/ride presentation is currently inadequate; future in-car UX remains to be tested. |

- **Overall initial outcome:** **4/4 False for CURRENT debug-build playability**; **evaluation context invalid/misleading for judging the proposed production experience**. Do not collapse this into a measured usability score or treat it as four independent validated root causes.
- **Related feedback IDs/issues:** FB-001 → #51; FB-002 → #49; FB-003 → #52; FB-004 plus dialogue/ride presentation → #50, #51. No new duplicate issue needed.
- **Decisions/implementation:** Existing #49–#52 remain **Accepted direction / Not implemented**. No source changes, player-mode UI or city pass occurred just because this checklist was recorded.
- **Technical evidence of a revised build:** **None**. Existing Linux/Web tests validate simulation mechanics, not these four human comfort goals.
- **Next check:** once a first genuine Player Mode and meaningful road scale exist, offer a small **specific** in-game interaction for optional user evaluation, without requiring a repeated full checklist or pre-claiming an improvement.
- **Human acceptance of improved gameplay:** **Pending / not assessed**, distinctly from the current baseline's four False answers.

## Guiding invariants

- Natural ride lengths arise from road geometry/topology, street speed and meaningful travel, not simply multiplying fixed 10-minute edges or penalizing the player for reading dialogue.
- Debug Mode and Player Mode are **two presentations of the same game world**; preserving developer evidence cannot dictate player-first HUD structure.
- A visually crossing elevated deck has **no legal junction** unless connected by a real explicit ramp/graph node. Vehicle animation follows road geometry, not screen-space hacks.
- Preserve the strengths of one `SandboxWorld`, real systemic fares, Ink meaning, player-only knowledge, source-backed rumors, deterministic replay and existing language/AR save behavior.
