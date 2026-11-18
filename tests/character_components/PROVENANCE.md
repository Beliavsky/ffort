# Feature provenance and validation stages

Base: certified 0.48.0 r2 source archive, SHA-256
`dde3fff9675e86dde2e4f13929bb1634ca59f43ba7694ff2bc908c13e8c42934`.

The source cases are original regression fixtures; `exact.f90` preserves the user's
reported scalar CHARACTER component program. SOURCE-IDENTITY.json pins each source.
GNU execution/compilation is the independent language oracle, not evidence that
FortFront already supports a feature. Invalid sources and supported-subset boundaries
remain separately classified. No Windows execution has been performed in this lane.

First implementation candidate 0.49.0 SHA-256:
`92fad0c3cd322053840e4fbf3e374af027c3e05dbe37e9687315fd673b8d56cf`.
Its initial 28 source cases and 60 native checks passed, including the exact user
example. Expanded first-control runs deliberately retained the recursive reservation
failure before the new guard existed. No large output-expansion mutation was run
against the first candidate or GNU.

An independent read-only review found and prompted corrections for direct component
kind/shape validation, schema agreement at packing, staged assignment before commit,
record-owned payload reservation, expression cycles, repeated operand references,
staged whole-record output, zero-length schemas, and hidden record value caches.
The final reviewed followup is SHA-256
`193b9db4faf17545ba5d268eaf4e45a36cb1137158ada6902f5a3f729e20e297`.
The scope is the record-owned admission contract described in README.md, not a new
global CHARACTER or process-heap guarantee. Sources without CHARACTER-bearing
record schemas retain the preexisting behavior. Independent read-only review passed
before the final candidate build; final execution evidence is recorded separately.

Historical promotion: unchanged `derived_defaults/character_component_boundary.f90`,
SHA-256 `43e006ad045495dfc5a4e7ad3ea2859db3df3752fba17aa3e2b8cb6a4ef1f7f6`,
is now expected to check and execute successfully with empty stdout. Its original
rejection was a deliberate prior feature boundary, not an invalid Fortran source.
The separate mixed-initialization promotion is maintained by that feature's owner.

## Final candidate source verification

Native adversarial checks on the first hardened candidate exposed an independent
adapter omission for component kind metadata. This was fixed, not waived; read-only
review also added base CHARACTER-length sentinel parity. The additive adapter patch
SHA-256 is `4be8c8aa248c9b1c83bc60f7872a05bfe0ab83572152373a4370b4d2cdec00ea`.

Final immutable candidate SHA-256:
`4a442ba1e9bb51dbe72d58708dbefe1d591717fa8f7a8b7f18a39b01466d53aa`.
Before/after hashes agree. Focused source cases: 34/34; harness tests: 34/34.
GNU classified results: 26 execute, 5 compile-only, 3 invalid-source rejections.
Affected historical suites pass: derived_types 43/43, fixed_character_derived_actuals
20/20, fixed_character_derived_scope 9/9, dynamic_character_constructor 72/72, and
both explicitly promoted derived_defaults boundaries within 47/47 cases.

The native fixture's synthetic function result identifier `out` was changed to
`answer` after exposing the preexisting reserved-name subset restriction. This is
only a fixture correction; failed evidence is retained and no assertion was removed.

Final native source SHA-256
`8037df71c67e85f2c452941868456d92cc4d2acd074e1675162c35dad7374079`
passes all 154 assertions on the final candidate's exact-profile shared library.
The 257-record staged-output mutation ran only on the guarded final candidate with
a 30-second timeout and bounded defined output; it rejected at the 16 MiB staged
output cap as expected. No unsafe old-candidate or GNU expansion was attempted.

Implementation patch order: original feature `ab244c1d`, record/runtime hardening
`193b9db4`, adapter parity `4be8c8aa`. Mixed initialized component declarations are
an independently maintained parser change. The two historical promotions alter
expectations only; all historical source bytes remain unchanged.
