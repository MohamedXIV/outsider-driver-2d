# P1 Playtest Builds — First Authentic Taxi Ride

These are short **playtest** builds, not a content-complete demo or a visually finished release. The native and browser distributions are built from the same Godot 4.7.2 project/commit.

## Download

Open [the validated playtest build run #38637520099](https://github.com/MohamedXIV/outsider-driver-2d/actions/runs/38637520099) and download its **outsider-driver-p1-playtest-builds** artifact from **Artifacts**. This artifact is retained for **21 days**, and contains three compressed platform bundles. All three internal archives were checked for integrity and expected binary/site files.

- **Windows x86_64:** unpack `outsider-driver-p1-windows-x86_64.zip` completely and launch `outsider-driver.exe`. Keep any accompanying data files next to the executable.
- **Linux x86_64:** extract `outsider-driver-p1-linux-x86_64.tar.gz` and run `./outsider-driver.x86_64`; use `chmod +x outsider-driver.x86_64` if needed.
- **Web:** extract `outsider-driver-p1-web.zip`, host the extracted folder with an HTTP server (for example `python3 -m http.server 8765`) and visit `http://localhost:8765/index.html`. Opening `index.html` as a `file://` page is **not supported**.

Web save persistence depends on the browser/profile and the site's origin. Use the **same URL and profile** to test Save → page reload → Load; different ports or private browsing sessions can have different storage.

## Current playable journey

1. **Pick up visitor** at Dockside. Taxi begins following the authored clinic route.
2. Respond to the visitor's inspection-arch question. Asking about service roads teaches a route fact; pretending you know the road raises the visitor's suspicion.
3. The taxi travels while dialogue is visible. Once the taxi arrives, the world clock keeps ticking.
4. Choose **Talk at destination**, then one of the authored exit replies to complete the ride and collect 18 credits.
5. Try Save/Load, including reloading mid-conversation and after completion. Completed fares must not be collected twice.
6. Cabin framing can be toggled in the passenger overlay. `R` resets the current test shift.

## Feedback still needed from a human

- Is the framing close and readable enough during the moving part of the ride?
- Does the conversation remain easy to read before arrival, without rushed clicking?
- Is the **Talk at destination** → two authored replies exit obvious and satisfying?
- Can you clearly find Pickup, Save, Load and the cabin-frame toggle?
- Does the passenger feel like part of a taxi ride rather than a detached UI prototype?
- Were there any issues with native Windows start-up or Web browser persistence?

Send observations or screenshots, especially the platform/browser and whether the issue occurred before or after arrival. This is a qualitative playtest gate and **has not been completed by automated testing**.

## Verified vs unverified

Godot native domain/Ink tests, Linux export/boot, visible Linux editor-scene walkthrough and real Chromium pointer playthrough passed in P1.3–P1.5. The Windows build produced by this workflow is an **export verification only**, not an executed Windows gameplay test. The city, road geometry and portraits currently use placeholder art. Do not claim final polish, human pacing validation or Windows runtime verification from a green export step.
