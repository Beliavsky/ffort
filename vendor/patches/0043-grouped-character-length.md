# 0043: Grouped CHARACTER declaration length metadata

Local compatibility patch against the bundled MIT-licensed FortFront source.
Upstream notices remain unchanged; upstream authorship or endorsement is not
implied. Apply after patch 0042 with `patch -p1` in `vendor/fortfront`.

The grouped declaration emitter preserves CHARACTER length-expression tokens
on each emitted declaration. OPTIONAL before INTENT can select this path even
for a single entity. Losing these tokens incorrectly turns fixed or assumed
length into a default length and breaks the independent adapter comparison.
No acceptance or semantic checks are weakened.

`test/test_optional_character_producer.f90` queries OPTIONAL and length metadata
for both attribute orders, single/grouped scalar declarations, and fixed/assumed
length. `test/test_optional_character.f90` independently checks adapter and
runtime descriptor integrity. The patch is an exact diff against the 0.26.0
archive's producer file.
