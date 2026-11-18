# 0055: CHARACTER argument declaration lengths

Local MIT-licensed FortFront metadata correction. The strict argument checker
previously converted a declared CHARACTER dummy to a bare CHARACTER tag and
silently treated its element length as zero. Preserve literal/default lengths
before wrapping array ranks. Resolve actual variable/element/section lengths
from their own declaration rather than provisional inference from another scope.

A nonliteral or assumed length is unresolved here, not a known zero length.
Unknown lengths defer storage compatibility to the independent interpreter
adapter/runtime contract. Known mismatched array lengths still fail the strict
producer check; kind and rank matching are unchanged. Scalar CHARACTER prefix
association remains unchanged. Runtime exact array element-length checks apply
even to empty arrays and to forwarding from assumed-length dummies.

Tests independently assert five declaration length descriptors, matching calls,
known mismatches and unknown-length forwarding. The focused explicit-dummy corpus
covers matching/default/zero lengths and runtime mismatches behind an assumed-
length wrapper. Five existing known-array-length mismatch cases now reject at
check time rather than runtime; their source inputs remain byte-identical.

Apply this source patch with `patch --fuzz=0 -p1` inside `vendor/fortfront`.
It was made against frozen 0.31 vendor sources and does not alter the parser.
