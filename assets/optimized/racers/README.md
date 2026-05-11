# Optimized Racer Assets

This folder is the staging point for racer GLBs exported by `C:\code\TeraPixel\asset-pipeline`.

The runtime resolver expects this layout:

```text
assets/optimized/racers/rexx/rexx_racer_in_kart_mobile_detail_phase1.glb
assets/optimized/racers/moko/moko_racer_in_kart_mobile_detail_phase1.glb
assets/optimized/racers/tuggs/tuggs_racer_in_kart_mobile_detail_phase1.glb
assets/optimized/racers/popper/popper_racer_in_kart_mobile_detail_phase1.glb
assets/optimized/racers/sir_clink/sir_clink_racer_in_kart_mobile_detail_phase1.glb
assets/optimized/racers/slammo/slammo_racer_in_kart_mobile_detail_phase1.glb
assets/optimized/racers/velva/velva_racer_in_kart_mobile_detail_phase1.glb
assets/optimized/racers/dash/dash_racer_in_kart_mobile_detail_phase1.glb
```

`racer/assets/profile` is set to `mobile_detail_phase1` for this phase. The current staged GLB total is about 208.4 MB, down from about 437.6 MB for the source racer-in-kart files. Godot also extracts one 2048 atlas JPG per racer during import; those source texture files add about 33 MB in the working tree.
