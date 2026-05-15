# Home Estate V1 Blender Shell Angle Review

Source: `scripts/tools/create_home_estate_shell_blender.py`

This review set exists to prevent accepting a shell from one flattering image. The Blender shell must be checked from every normal exterior and gameplay-adjacent angle before it is treated as a production candidate.

| View | Current result | Notes |
| --- | --- | --- |
| FrontStreetReviewCamera | partial | Reads as a modern farmhouse front with porch, garage doors, gables, edge-derived trim, and glass. Still needs material/detail pass. |
| RearYardReviewCamera | partial | Rear massing is coherent enough for scaffold validation, but patio/backyard dressing remains sparse. |
| LeftSideReviewCamera | partial | No broad floating roof slab; side wall now reads as a continuous wall panel. Eave fascia is endpoint-derived instead of an approximate gable bar. Needs more side openings/service detail. |
| RightSideReviewCamera | partial | Side massing is no longer a literal floor-plan extrusion, but still needs facade refinement. |
| FrontThreeQuarterReviewCamera | partial | Strongest current read; roof hierarchy and porch are legible. |
| RearThreeQuarterReviewCamera | partial | Confirms rear/side continuity, but backyard architecture is under-detailed. |
| RooflineReviewCamera | partial | Roofs are integrated solid gable meshes with endpoint-derived ridge, eave, and rake trim, not separate Godot lid slabs. Valleys remain simplified. |
| UndersideOverhangReviewCamera | partial | No oversized full-footprint soffit closure visible, and the former approximate straight gable-end trim bars have been replaced by sloped rake members. Porch overhangs still need final underside material/detail. |
| FrontLeftEaveSeamCamera | gate-required | Close seam camera for the front-left eave/rake joint. Must be reviewed as pass before shell production acceptance. |
| FrontRightEaveSeamCamera | gate-required | Close seam camera for the front-right eave/rake joint. Must be reviewed as pass before shell production acceptance. |
| RearLeftEaveSeamCamera | gate-required | Close seam camera for the rear-left eave/rake joint. Must be reviewed as pass before shell production acceptance. |
| RearRightEaveSeamCamera | gate-required | Close seam camera for the rear-right eave/rake joint. Must be reviewed as pass before shell production acceptance. |
| UndersideLeftEaveSeamCamera | gate-required | Close underside seam camera for left eave/rake closure. Must be reviewed as pass before shell production acceptance. |
| UndersideRightEaveSeamCamera | gate-required | Close underside seam camera for right eave/rake closure. Must be reviewed as pass before shell production acceptance. |
| MainFrontGableApexCamera | gate-required | Close main front gable apex camera. Must prove rake boards, ridge cap, and apex cap resolve to a visible point instead of squared beam ends. |
| MainRearGableApexCamera | gate-required | Close main rear gable apex camera. Must prove the rear rake boards and ridge cap converge with an apex cap. |
| GarageFrontGableApexCamera | gate-required | Close garage front gable apex camera. Must prove the garage cross-gable apex is capped and not forked. |
| GarageRearGableApexCamera | gate-required | Close garage rear gable apex camera. Must prove the rear garage gable apex is capped and not forked. |
| MasterFrontGableApexCamera | gate-required | Close master-wing front gable apex camera. Must prove the side-wing gable point is closed. |
| MasterRearGableApexCamera | gate-required | Close master-wing rear gable apex camera. Must prove the rear side-wing gable point is closed. |
| RearMasterWingRoofClosureCamera | gate-required | Close rear/side roof-intersection camera for the master wing tie-in. Must be reviewed as pass before shell production acceptance. |
| RearPorchRoofTieInClosureCamera | gate-required | Close rear porch roof tie-in camera. Must be reviewed as pass before shell production acceptance. |
| GarageRearRoofClosureCamera | gate-required | Close garage rear roof closure camera. Must be reviewed as pass before shell production acceptance. |
| FrontPorchRoofTieInClosureCamera | gate-required | Close front porch roof tie-in camera. Must be reviewed as pass before shell production acceptance. |
| RightWallFlushCloseCamera | gate-required | Close right-side wall-plane camera. Must prove wall slabs share declared exterior planes and corner returns intentionally cover seams. |
| MasterWingFrontReturnFlushCamera | gate-required | Close master-wing corner-return camera. Must prove the side wall, return trim, and adjacent facade do not form an accidental proud/recessed step. |
| GarageSideReturnFlushCamera | gate-required | Close garage/service-side return camera. Must prove garage wall and corner return are plane-aligned instead of approximate overlapping boxes. |
| RightFrontRoofWallEdgeCamera | gate-required | Close front-right roof/wall corner edge sweep. Must prove fascia, rake, wall top, and backer return hide black slits and floating trim. |
| RightRearRoofWallEdgeCamera | gate-required | Close rear-right roof/wall corner edge sweep. Must prove fascia, rake, wall top, and backer return hide black slits and floating trim. |
| MasterWingOuterRoofWallEdgeCamera | gate-required | Close master-wing outer eave edge sweep. Must prove the long eave, wall plane, and backer return read as one envelope edge. |
| GarageOuterRoofWallEdgeCamera | gate-required | Close garage/service-side eave edge sweep. Must prove garage roof trim and wall top terminate cleanly at the corner. |
| PorchRoofWallEdgeCamera | gate-required | Close porch tie-in roof/wall edge sweep. Must prove porch eave trim and the main wall backer do not leave exposed edge gaps. |
| MainRightInteriorCeilingClashCamera | gate-required | Interior-side clash camera for the main right eave/wall top. Must prove exterior-only backers and trim do not enter the finished room or ceiling clearance volume. |
| MasterWingInteriorCeilingClashCamera | gate-required | Interior-side clash camera for the master wing eave/wall top. Must prove the exterior edge seal remains outside the room envelope. |
| GarageInteriorCeilingClashCamera | gate-required | Interior-side clash camera for the garage/service eave/wall top. Must prove exterior-only seals do not pierce the garage ceiling or room clearance. |
| UpperEaveUndersideClashCamera | gate-required | Underside clash camera for upper eave/corner fixes. Must prove perimeter closures seal the edge without creating route/camera blockers. |

Gate outcome: improved scaffold candidate, not final beta art. The previous failure classes, independent broad roof/soffit slabs, approximate trim bars blocking side/underside views, proud/recessed wall-plane seams, unreviewed roof-wall corner edge slits, uncapped gable apexes, and wrong porch-roof axis, are reduced by moving shell geometry into one Blender-authored wall/roof assembly, deriving trim from roof-edge endpoints, adding wall-plane, roof-wall edge, gable-point, roof-axis, and envelope clash audits, and suppressing primitive Godot roof fallback when the GLB exists.
