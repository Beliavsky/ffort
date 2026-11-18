# Release 0.26 integration checks

Six independent fixtures combine allocatable CHARACTER descriptors, simultaneous FORALL assignments, rounding intrinsics, assumed-length allocatable output dummies, shape changes and zero-sized descriptors. Five successful programs compare against literal expectations and GNU Fortran. A duplicate CHARACTER target checks runtime rejection without output and uses GNU only as a compile check.

`original_body_composition.f90` retains four original utilities procedure bodies (`munge`, `floor_10`, `ceiling_10`, `set_alloc_character_vec`) unchanged apart from CRLF-to-LF normalization. `original-bodies.json` records exact source and body hashes. The surrounding module/driver are new. This is not evidence that the whole utilities module executes.
