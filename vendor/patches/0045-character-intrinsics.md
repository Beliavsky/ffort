# 0045: CHARACTER intrinsic metadata

Local changes to the pinned MIT-licensed FortFront source independently derive
canonical elemental rank for INDEX, LEN_TRIM, ADJUSTL and ADJUSTR. INDEX and
LEN_TRIM INTEGER result kinds are derived from positional or named KIND source
arguments, including reordered keywords and absent INDEX BACK. ADJUSTL/ADJUSTR
retain default CHARACTER kind 1. Existing registry entries are reused; strict
semantic analysis is not bypassed. The interpreter separately restricts result
integer kinds to 4/8 and operand rank to zero/one/two.

Apply after previous patches with `patch -p1` in the vendor source root.
The independent producer test checks 18 source-derived metadata results.
