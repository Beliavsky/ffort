# 0086: ASCII lexical comparison metadata

Local MIT-licensed producer extension for LGE, LGT, LLE and LLT. Adds four unique
function registry identities (114 to 118), conforming elemental rank metadata and
fixed default LOGICAL result type/kind. Arguments are checked separately as default
CHARACTER in the adapter/runtime; no lexer reservation is introduced.

Apply with `patch --fuzz=0 -p1` from the cumulative vendor root after 0085.
0085 retains 114 function identities and changes the subroutine list to 44; this
patch preserves that GETCWD change. Replay after 0085 was verified without offsets
or fuzz. The feature core already includes the raw vendor edits, so do not apply
both copies. Later TRANSPOSE/NORM2 metadata must be composed additively.
