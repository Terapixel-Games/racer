# Optimized Racer Assets

This folder is the staging point for racer GLBs exported by `C:\code\TeraPixel\asset-pipeline`.

The runtime resolver expects this layout:

```text
assets/optimized/racers/rexx/rexx_racer_in_kart_mobile_detail.glb
assets/optimized/racers/moko/moko_racer_in_kart_mobile_detail.glb
assets/optimized/racers/tuggs/tuggs_racer_in_kart_mobile_detail.glb
assets/optimized/racers/popper/popper_racer_in_kart_mobile_detail.glb
assets/optimized/racers/sir_clink/sir_clink_racer_in_kart_mobile_detail.glb
assets/optimized/racers/slammo/slammo_racer_in_kart_mobile_detail.glb
assets/optimized/racers/velva/velva_racer_in_kart_mobile_detail.glb
assets/optimized/racers/dash/dash_racer_in_kart_mobile_detail.glb
```

Set `racer/assets/profile` to `mobile_detail` when these files are staged. Until then, `RacerRoster` falls back to source models.
