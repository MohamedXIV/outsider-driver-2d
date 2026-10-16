# Outsider Driver — Playability Feedback Register

> **Living human-feedback register / first entry October 16, 2026.** [Central discussion & workstream board: #48](https://github.com/MohamedXIV/outsider-driver-2d/issues/48). [Execution roadmap](SANDBOX_EXECUTION_ROADMAP.md). This is a product feedback record, NOT a QA pass, sprint calendar or duplicate implementation backlog.

## Baseline: what is actually known

- **Gameplay:** Godot 4.x 2D / axonometric sandbox driven by one authoritative `SandboxWorld`; systemic nine-NPC sample, real Ink conversations, priced translator/AR equipment, physical store, seeded fare dispatch, road graph routes, reroute and persistent social encounters. [Last verified baseline before this feedback](https://github.com/MohamedXIV/outsider-driver-2d/commit/4c9c848b467baa4a1bcb4b30c35f31504db62936).
- **Visuals:** `SandboxRoads` presently has **five district nodes** linked by a simple graph; `SandboxCityView` draws **straight lines** between district projections and interpolates taxi motion linearly. This is a schematic playable engineering sample, *not* evidence of a real-scale, physically rich city or believable bridges.
- **Human feedback:** user reports information overload / confusing debug text, rushed and fragmented trip experience, and wants naturally larger urban distances, engaging UI and curved/elevated natural-looking roads.
- **Unobserved:** there is NO submitted detailed personal checklist, numerical pacing score, artistic reference or user approval of an implemented Player Mode/large city/splines. Do not invent these. Green native/Web checks prove functional gameplay invariants, **not** human comfort or appearance. Windows release export is not actual Windows runtime.

## Long-lived observations (IDs never recycled)

| ID | Original observation / direction | Owner issue | Priority | Current status | Technical proof | Human acceptance |
|---|---|---|---|---|---|---|
| **FB-001** | Trips feel too short and pressuring to notice passenger, read/talk, enjoy road scenery. **Approved correction:** a sufficiently large and varied city should naturally give rides breathing room, rather than fake time dilation. | [#51](https://github.com/MohamedXIV/outsider-driver-2d/issues/51) | High | **Accepted direction — not implemented** | None after this feedback | **Pending** |
| **FB-002** | Existing on-screen diagnostic texts cause confusion and compete with playing. **Approved:** default Player Mode + explicit reversible Debug Mode for developer telemetry. | [#49](https://github.com/MohamedXIV/outsider-driver-2d/issues/49) | First slice | **Accepted direction — not implemented** | None after this feedback | **Pending** |
| **FB-003** | Roads should look organic: splines/curves, real-feeling bridges, flyovers and sensible elevation instead of toy straight lines. | [#52](https://github.com/MohamedXIV/outsider-driver-2d/issues/52) | High, coordinated with #51 | **Accepted direction — not implemented** | None after this feedback | **Pending** |
| **FB-004** | Player HUD should be attractive, intuitive, supportive and readable, rather than merely debug controls with colors. | [#50](https://github.com/MohamedXIV/outsider-driver-2d/issues/50) | High, builds on #49 | **Accepted direction — not implemented** | None after this feedback | **Pending** |

**Follow-up checklist:** User explicitly said they will return with it later. **Do not prompt repeatedly, invent responses, schedule mandatory check-ins or mark a category approved by the user beyond the directions actually stated.** Append each later note with its original date and exact framing; create a new FB ID only for an independent new problem.

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
- **Human verdict on revised build:** **Pending**; no revised build submitted, user's checklist will arrive later.
- **Next action:** implement #49 as the first independently playable slice; coordinate #51/#52 topology and track one real passenger ride and world/route visibility. Wait for user-provided checklist whenever they choose to send it.

## Guiding invariants

- Natural ride lengths arise from road geometry/topology, street speed and meaningful travel, not simply multiplying fixed 10-minute edges or penalizing the player for reading dialogue.
- Debug Mode and Player Mode are **two presentations of the same game world**; preserving developer evidence cannot dictate player-first HUD structure.
- A visually crossing elevated deck has **no legal junction** unless connected by a real explicit ramp/graph node. Vehicle animation follows road geometry, not screen-space hacks.
- Preserve the strengths of one `SandboxWorld`, real systemic fares, Ink meaning, player-only knowledge, source-backed rumors, deterministic replay and existing language/AR save behavior.
