# Home Yard V3 Live Camera Validation Retro

Date: 2026-05-12

## Current Live Validation Status

The racer stage repair loop is no longer stopped on the original live-camera blocker. After fresh-editor recovery, the managed Godot MCP server proved every public home course start camera through `editor_screenshot(source="cinematic")`: Kitchen, Attic, Playroom, Bedroom, Glam Closet, Outdoor Playground, Garden, and Sandbox each returned the expected active `camera_path`. Kitchen first-turn validation also returned `/HomeYardMap/ValidationCameras/KitchenFirstTurnPlayerCamera`.

## Current Kitchen State

Kitchen is partially improved but not production-gated. Focused unit and UAT coverage pass, helper route geometry was removed, and the serialized player-height camera was moved. Live editor screenshot proof now succeeds for both `KitchenStartPlayerCamera` and `KitchenFirstTurnPlayerCamera`, but kitchen still needs broader final production-gate review before release.

## Other Home Yard V3 Course State

The loop has completed concrete repair passes for attic, playroom, bedroom, glam_closet, outdoor_playground, garden, and sandbox. Recent deterministic checks show their shared route/camera contracts load and the start validation cameras can be made current through the Godot `Camera3D` API in headless tests. Live MCP proof has now succeeded for all of those non-kitchen start cameras after fresh-editor recovery, but the editor can still stall or briefly reject writes during import churn.

## Route And Shell Validation State

Focused route/shell validation is now backed by both deterministic tests and live cinematic camera metadata. The catalog listing test exercises the shared home_yard_v3 route envelopes, road-above-floor checks, closed route cells, vertical ramp contracts, exterior shell ownership, roof/attic contract, validation-only markers, landscape assets, kitchen readability helper cleanup, and route/shell validation camera current-camera selection. Live MCP cinematic proof has succeeded for `ExteriorRooflineCamera`, `RoofGambrelSideProfileCamera`, `AtticGableProfileCamera`, `MainFloorRouteStartsCamera`, `UpperFloorRouteStartsCamera`, and `YardCourseOverviewCamera`. Targeted viewport coverage for `/HomeYardMap/ValidationCameras/YardCourseOverviewCamera,/HomeYardMap/Yard` also succeeded with establishing and top-down captures over a yard AABB centered near `(-2.5, 119.45, -292.5)` and sized about `(655, 242, 325)`.

## Unreleased Blockers

- Live `editor_screenshot(source="cinematic")` has proven these start cameras can become active in the editor: `/HomeYardMap/ValidationCameras/KitchenStartPlayerCamera`, `/HomeYardMap/ValidationCameras/AtticStartPlayerCamera`, `/HomeYardMap/ValidationCameras/PlayroomStartPlayerCamera`, `/HomeYardMap/ValidationCameras/BedroomStartPlayerCamera`, `/HomeYardMap/ValidationCameras/GlamClosetStartPlayerCamera`, `/HomeYardMap/ValidationCameras/OutdoorPlaygroundStartPlayerCamera`, `/HomeYardMap/ValidationCameras/GardenStartPlayerCamera`, and `/HomeYardMap/ValidationCameras/SandboxStartPlayerCamera`.
- A temporary `@tool` script hook can now attach to Playroom when the editor is ready, but attaching alone does not force `_ready()` to rerun for an already-live node; the successful switch came from explicitly clearing Sandbox `current` and setting Playroom `current`.
- Camera writes can still be rejected by transient `EDITOR_NOT_READY` importing responses. Retrying after the readiness window has been enough to continue validation.
- The route/shell and yard overview live camera proof is complete; remaining production-gate risk is broad release review and unrelated dirty work rather than a known home_yard_v3 camera blocker.
- Godot headless test commands now return process exit `0` after the test runner drains a few cleanup frames before quitting. Shutdown resource/RID leak diagnostics still print and should be investigated separately, but they no longer mask passing focused tests as command failures.
- The repo has broad unrelated dirty and untracked work, so even a verified scoped commit would need careful staging.

## Why Existing Skills, Tests, And Generators Did Not Prevent This

The generator correctly creates the validation cameras, and deterministic tests now prove those cameras can be made current via Godot's public API. Earlier loop iterations used MCP `view_target` as if it selected the cinematic camera, so stale kitchen captures were initially misread as stage-layout failures. The guidance has since been clarified, and the live editor integration can now validate a non-kitchen current camera when the editor is ready, but it still needs a repeatable multi-camera validation command that avoids import/cache churn.

## Missing Capability

The loop needs a deterministic live-camera validation runner that can:

- open or hydrate the scene from disk without depending on unstable editor import state,
- set a named `Camera3D` current in-process,
- capture a screenshot or metadata proving the active `camera_path`,
- restore or avoid mutating the authored scene,
- return a normal process exit code when assertions pass.

## Required Change Before Restarting

Before claiming the production gate, add or fix a validation path that bypasses the remaining MCP editor write instability. A good next step is a headless/scripted Godot validation command for `home_yard_v3` that iterates the public start cameras, calls `make_current()`, captures or records the current camera path, and emits clean pass/fail output without relying on MCP `node_set_property` during editor import.
