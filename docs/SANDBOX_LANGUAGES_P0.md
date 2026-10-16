# Languages P0 — Three Shared City Languages, Binary Modules and Market

**Status:** Verified gameplay slice, October 16, 2026. [PR #45](https://github.com/MohamedXIV/outsider-driver-2d/pull/45), gameplay head `34d977e4fb9d7d8bf0961db019514987bf16e0f9`. [Godot 4.7.2 validation #38835072560](https://github.com/MohamedXIV/outsider-driver-2d/actions/runs/38835072560) **SUCCESS**; Linux native Godot + exported Chromium real UI + preserved regression. This document records the accepted product change; historical [S2](SANDBOX_S2.md) remains an archival proof and is no longer the language specification.

## Player-visible contract

1. Everyone starts with a **Basic Translator with Common/Trade installed**; choose exactly one additional **GPS / Local language module (preinstalled) / Radio**. No legacy standalone Translator choice and no learned single-word scanner.
2. Nine persistent NPCs speak one of exactly **three shared** city languages: **Trade**, **Local**, **Cant**. Species is independent: e.g. `npc:01` and `npc:04` speak Local although they differ in species. Two speakers of the same language use the **same cartridge**. Individual `speaks_common` and `will_use_common` abilities independently affect Common requests.
3. Uninstalled language = **no translation**; installed cartridge = **the entire supported reusable Ink speech act is understood**. Asking for a destination, accepting a fare, or declining still goes through the world-validated conversation and transaction. No partial translation or progress bar.
4. Local cartridge **8 cr** and Cant cartridge **9 cr** at `vendor:market:language-stall`. The player must **actually drive to Market** and shop during **06:00–20:00**. Purchase consumes credits and one finite stock item exactly once, changes **owned inventory but not installed access**; a separate Install button activates the language. A visible Market stall and one-click market navigation use the same charged `SandboxWorld.reposition` road authority.
5. A rider may or may not switch to Common based on language ability, attitude and urgency. The request is once per live offer, has an event-sourced response, survives mid-conversation Save/Load and never magically promotes an unsupported language.
6. `SandboxWorld` remains the only source of truth: `modules_owned`, `modules_installed`, `market_stock`, `common_requests`, credits, NPC abilities and event provenance. `SandboxKnowledge` is a pure policy helper; Ink and HUD present state or submit validated commands. Schema v9, save envelope v10; intentionally no old experimental save migration.

## Reuse / Replace / Retire

| Kind | Exact surface | Rationale |
|---|---|---|
| Reuse | `SandboxWorld` event ledger, `SandboxPopulation`, `SandboxConversation`, Ink Bridge, `SandboxSave`, `SandboxRoads` | Same single authoritative seed/simulation, genuine offers, route/economy and grounded semantic Ink |
| Replace | `SandboxKnowledge`, `SandboxWorld.select_starter_device`, `scripts/sandbox/sandbox_main.gd`, `scenes/sandbox.tscn` | Free Common + binary cartridge, individual NPC fallback and physical-market choices instead of obsolete S2 device demonstration |
| Retire | `observe_route_language`, `ROUTE_MARKER`, `recognizes_route` and obsolete S2 partial-scanner tests | Learning one route word is explicitly no longer the product contract; no parallel feature kept to satisfy historical green tests |
| Update tests | `tests/test_sandbox_knowledge.gd`, `tests/test_sandbox_scene.gd`, `tests/web_sandbox_smoke.cjs`, `tests/web_sandbox_reroute.cjs` | Whole-language before/after, provenance/idempotency, NPC refusal and acceptance, market purchase/install, real browser reload and historical route test geometry |

## Actual verification, not inferred behavior

- **Headless native domain:** three languages, shared language across distinct species, free Common, bonus choice, distinct Cant speech, intentional fallback refusal/acceptance, physical-market gating, 8/9-credit prices, single purchase, separately installed module, no partial reading, replay, impossible-state restore rejection, full Ink choice persistence: `SANDBOX_KNOWLEDGE_PASS`.
- **Linux native visible scene:** uninstalled NPC, Market navigation and purchase, wallet/stock/inventory changes, install, comprehensible Ink destination, saved mid-Ink restore, actual fare once: `SANDBOX_SCENE_PASS` with screenshots.
- **Exported Chromium UI automation:** real button clicks for speaker/Common request/refusal, physical travel, vendor purchase, separate installation, full comprehension, Web filesystem reload during Ink, actual fare settlement: `SANDBOX_WEB_PASS`.
- **Regression:** Sandbox S0/S1/S3 population, autonomy, peer contact, driver memory, off-duty meeting, route movement and reroute all passed native and Chromium. UI route controls are now hidden behind an active Ink or meeting panel to avoid overlap; the reroute test clicks the actual Godot button rectangle.
- **Artifacts:** [Linux, Windows and Web exports](https://github.com/MohamedXIV/outsider-driver-2d/actions/runs/38835072560/artifacts/12018708030) and [native/Web screenshot evidence](https://github.com/MohamedXIV/outsider-driver-2d/actions/runs/38835072560/artifacts/12018558678).

**Explicitly unverified:** actual Windows runtime (Windows exported only), subjective play feel, accessibility perception and visual polish. These scripted and romanized speech surfaces are provisional. **[#33](https://github.com/MohamedXIV/outsider-driver-2d/issues/33)** will implement licensable alien glyph fonts, stable source script, localized reveal to selected UI locale including Arabic RTL and reduced motion. No claim here that #33's display/localization work is complete.
