# Racer Package Size Phase 3 Mesh Quantization Result

Phase 3 is blocked as a production path for Godot imports.

## Result

- `gltfpack` quantization reduced the eight LOD0 racer GLBs from `218,483,632` bytes to `160,454,480` bytes.
- That is a `58,029,152` byte reduction before Godot import.
- Godot 4.5.1 rejected the generated GLBs because they require `KHR_mesh_quantization`.

## Gate Decision

The phase fails the import gate and remains off the production roster. `mobile_detail_phase1` stays the configured baseline.

## Notes

- A compatibility trial with float vertex attributes imported successfully, but it produced no meaningful size reduction.
- The asset-pipeline repo now has a research profile for this path, but racer production assets should not use it until Godot supports the required extension or we add a verified importer path.
