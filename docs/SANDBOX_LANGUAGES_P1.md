# Languages P1 — Stable Alien Scripts and Localized Dialogue

**Status:** Verified gameplay slice, October 16, 2026. [PR #46](https://github.com/MohamedXIV/outsider-driver-2d/pull/46), gameplay head `2232b4504d31de48ce9cb396896e6b302a853bfb`. [Godot 4.7.2 CI #38838251079](https://github.com/MohamedXIV/outsider-driver-2d/actions/runs/38838251079) **SUCCESS (31/31 workflow steps)** on official Linux Godot, exported Linux, Windows export and exported Chromium Web. [Builds](https://github.com/MohamedXIV/outsider-driver-2d/actions/runs/38838251079/artifacts/12020391466) · [Native and Web screenshots](https://github.com/MohamedXIV/outsider-driver-2d/actions/runs/38838251079/artifacts/12019779612).

## What the player sees

- The authoritative [P0 contract](SANDBOX_LANGUAGES_P0.md) remains: Trade/Common installed by default, Local or Cant purchasable and separately installed, once-per-offer genuine NPC Common negotiation. No extra translator, incremental grammar progress or world model.
- `SandboxLanguagePresentation` maps **six stable taxi speech meanings** per language to **distinct authored scripts**. Local uses a Runic-shaped glyph vocabulary; Cant uses Ogham-shaped glyphs. Repeated utterance/semantic key + language yields identical script across NPCs, seeds and user interface locales. These visual choices are **provisional fiction aesthetics based on historical scripts**; do not call them complete alien linguistic systems.
- When the cartridge is absent, `SandboxConversation` presents only the alien source line, never Ink's historical English stage directions, route destination, or "recognizes your taxi" clue. It still uses genuine Ink speech act tags and validates the same fare through `SandboxWorld`. "Ask to speak Common" respects speaker fluency, willingness, urgency and prior request.
- With the cartridge, the native glyph line precedes a **0.7-real-second** presentation-only reveal into the player's selected **English or Arabic** text. Skip reveals immediately; Reduced Motion and browser `prefers-reduced-motion` bypass the delay. Reveal uses `_speech_identity` to avoid restarting on autonomous world ticks. Dialogue choices remain actionable; localization changes labels only, not Ink choice indices/commands.
- The locale switch selects Arabic **RTL/BiDi for translated dialogue and choices**. Alien source glyphs keep their own LTR display even inside Arabic UI, reverting to RTL after reveal or skip. The small semantic catalog has authored Arabic for recurring intro contexts, destinations (five districts) and purposes (four goals), with English from compiled Ink. Neither unsupported linguistic facts nor a fabricated omniscient translation appear.

## Licensed font assets and reproducibility

Fonts are shipped inside `assets/fonts/`, sourced from the public [Google Fonts repository](https://github.com/google/fonts), each with its **exact SIL Open Font License (OFL)** text committed in the project:

| Usage | Vendored font | Upstream and vendored license |
|---|---|---|
| Local | `NotoSansRunic-Regular.ttf` | `google/fonts/ofl/notosansrunic`; `LICENSE-local-OFL.txt` |
| Cant | `NotoSansOgham-Regular.ttf` | `google/fonts/ofl/notosansogham`; `LICENSE-cant-OFL.txt` |
| Arabic | `NotoNaskhArabicUI[wght].ttf` | `google/fonts/ofl/notonaskharabicui`; `LICENSE-arabic-OFL.txt` |

Native scene QA calls `Font.has_char` on every authored glyph in both alien languages and representative Arabic letters, and captures actual RTL dialogue. Chromium acceptance displays Local glyphs and Arabic text in the Web release. This checks the current small script inventory, **not every possible future Unicode text**.

## Automated acceptance

- `SANDBOX_SEMANTIC_INK_PASS`, `SANDBOX_KNOWLEDGE_PASS`: bound Ink speech tags, Common refusal/acceptance, full language modules, physical market, saved Ink and no route/identity spoilers.
- `SANDBOX_LANGUAGE_SCENE_PASS`: visible Linux scene font inventory, untranslated Local, actual Market cartridge installation, source glyph, Arabic skip and RTL, reduced-motion immediate Arabic destination, then return to English; saved screenshots `languages-arabic-native.png` and `languages-arabic-reduced-native.png`.
- `SANDBOX_WEB_PASS`: Chromium clicks real controls, checks unknown Local glyph/no English narrative leak, Arabic choice labels, reduced motion, physical shop and module installation, mid-Ink browser reload, post-reveal choice layout, single actual fare settlement; screenshots `sandbox-arabic-rtl.png` and `sandbox-arabic-reduced.png`.
- S3 autonomous residents, route and reroute, peer history, returning-driver memory and voluntary off-duty Ink continue to pass native and Chromium. The obsolete English "recognizes your taxi" assertion was replaced with a real NPC memory assertion plus deterministic untranslated glyphs, **not** by leaking knowledge again.
- The reveal changes **presentation only** and never grants knowledge, adjusts world ticks or changes credits. A post-layout Web hitbox refresh handles the optional Skip button collapsing so touch/click targeting works after the reveal.

## Explicit non-claims and next work

- The current schematic/debug HUD is **not fully Arabic-localized**; the verified localized slice is contextual taxi dialogue, choices and their controls. Real Arabic UX across the entire app, screen-reader acceptance, actual small-phone hardware, accessibility preference persistence, and live Windows execution are **not verified**.
- No custom writing system or phonetic conlang generation; the six semantic phrases per language are a deliberately small authored P1 presentation inventory. No synthesized speech, source-to-translation glyph morph, full radio localization or social literacy progression.
- Optional [#34 AR knowledge-only hints](https://github.com/MohamedXIV/outsider-driver-2d/issues/34) is an independent next equipment slice, **not** a prerequisite to shipping these glyphs, and must never expose facts the player has not learned.
