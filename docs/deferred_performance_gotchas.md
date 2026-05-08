# Deferred Performance Gotchas

Last updated: 2026-05-06

This note tracks performance risks we have noticed but are not fixing immediately. Add to this list when a feature works functionally but leaves a loading, runtime, editor, memory, or asset-size concern that deserves a later focused pass.

## Triage Rules

- Do not treat every entry here as current scope.
- When a gotcha becomes user-visible, add reproduction steps and promote it to an active task.
- Prefer measuring before changing behavior. Capture file size, load time, frame time, node count, draw calls, or memory where possible.
- Keep editor-only tooling out of runtime paths unless there is a deliberate reason.

## Open Gotchas

### Large Imported GLB Assets In Runtime Scenes

Risk: Imported GLB scenes can become expensive when synchronously loaded during level select, race startup, or editor preview.

Observed during attic work:
- `jack_in_the_box_parts.glb` is about 40 MB.
- `jack_in_the_box_source.glb` is about 40 MB.
- Saving generated mesh children into `JackInTheBoxSetpiece.tscn` accidentally expanded the scene to about 81 MB.

Current mitigation:
- `JackInTheBoxSetpiece.tscn` was restored to a lightweight script-only scene.
- Generated jack-in-the-box parts are transient and should not be owned/saved into the scene.

Needs later investigation:
- Create optimized runtime versions of Meshy props with reduced mesh density and texture size.
- Add an asset-size budget for props used in level previews.
- Add a test or tooling check that flags `.tscn` files above a threshold when they embed mesh payloads.

### Authoring Preview Work Leaking Into Runtime

Risk: `@tool` authoring scripts can accidentally run preview-building code in gameplay or level-select contexts, causing stalls from scene instantiation and asset loading.

Observed during attic work:
- `StagePropAuthoring` built scene previews outside the editor, which could synchronously instantiate heavy GLB props when selecting a level.

Current mitigation:
- `StagePropAuthoring` preview generation is editor-only.

Needs later investigation:
- Audit all `@tool` scripts for `_ready`, `_process`, deferred preview refreshes, and `load().instantiate()` calls.
- Add a lightweight runtime assertion or test that authoring nodes do not create `GeneratedPreview` children outside `Engine.is_editor_hint()`.
- Decide whether authoring-only nodes should be stripped from runtime dressing scenes before packaging.

### Level Select Preview Builds Full Track Packages

Risk: Level select currently builds enough of the track package to preview it. As tracks become richer, this can become a UI-thread stall.

Observed during attic work:
- After removing heavy authoring previews, an attic runtime build measured about 78 ms headless. That is acceptable for now, but still a synchronous operation in a menu path.

Needs later investigation:
- Cache preview packages per track during level-select lifetime.
- Build simplified preview-only packages that skip dressing, prop GLBs, collisions, audio zones, and detailed rails.
- Consider async/deferred preview loading with a small loading state so UI remains responsive.

### Runtime Use Of High-Fidelity Setpiece Assets

Risk: Setpieces like the jack-in-the-box may need separate authoring and runtime assets. The authoring asset is useful for cleanup, but the runtime version should be tuned for gameplay budgets.

Observed during attic work:
- The jack-in-the-box source model is high detail and expensive enough that accidental embedding caused visible load issues.

Needs later investigation:
- Export an optimized runtime GLB after the part split is final.
- Keep source GLBs in a clearly marked source folder and use smaller runtime GLBs in gameplay scenes.
- Define acceptable triangle count, material count, texture size, and file size for animated props.

### Editor Preview Persistence

Risk: Editor-generated preview nodes become dangerous if they receive scene ownership and get saved into `.tscn` files.

Observed during attic work:
- Making generated jack-in-the-box children editor-owned made them selectable, but also caused the imported meshes to be packed into the scene.

Current mitigation:
- Generated jack-in-the-box parts remain transient.

Needs later investigation:
- Build a safer editor plugin or inspector workflow for manipulating transient preview parts without saving them.
- Add a check for generated node names such as `SourcePart`, `GeneratedPreview`, or imported mesh subresources in committed `.tscn` files.
