# 0105: bounded LEADZ metadata

Baseline: post-0104 generic/intrinsic REPEAT on corrected implementation-frozen 0.48 source-test-final-r2 ZIP, SHA256 dde3fff9675e86dde2e4f13929bb1634ca59f43ba7694ff2bc908c13e8c42934. This is not a claim that its independent release aggregate has completed. Patch number reserved after generic fallback 0104; apply once at vendor/fortfront with patch -p1, retaining the preceding generic changes.

Registers LEADZ once, increasing the intrinsic function registry from 126 to 127. Resolves elemental rank and default INTEGER kind 4 independently of input INTEGER kind 4/8. No lexer keyword is added. Existing symbol/procedure/generic precedence remains. The adapter/runtime separately enforce canonical I keyword, default result type/kind, supported input widths, shape and metadata/public-IR safety. LEADZ is a value operation, not an inquiry: only an enclosing KIND suppresses value reads.

The canonical raw patch replays against post-0104 with no offset, and both
resulting vendor files byte-match the combined tree. Focused corrected-preview
validation passes 59 source/GNU outcomes, 1,013 native public-IR/value assertions
and 3,773 adversarial harness checks. The separate adapter result-kind correction
is part of the core patch, not this vendor patch. Full release certification is
independent and remains the integrator's responsibility.
