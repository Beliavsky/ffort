# 0112: nested and named DO in implicit main programs

Apply after 0111 with `patch -p1` in `vendor/fortfront`. The statement boundary
scanner closes END DO once and does not count its DO token as a new opener.
Named DO keeps its label in the source slice while matching the complete body
from the DO token; the closing name is retained. The identifier dispatcher
routes the exact name-colon-DO form to the existing labeled DO parser.

This patch was reconstructed after a workspace reset. Its canonical patch
SHA-256 is byte-identical to the retained historical identity:
`945a2f6c9650eab4d55352eca612e344c2abfb59794a075e540607be9c166712`.
The three resulting source hashes also match the historical recorded files.
Zero-fuzz/zero-offset source replay is verified. This establishes reconstruction
identity, not a fresh candidate execution or full release certification.

The change preserves counted/bare/conditional control ownership and does not
relax independent adapter checks or add unrelated named constructs. Focused
DO WHILE and independent cross-control suites supply new validation evidence.
