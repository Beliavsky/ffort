# Bounded array-constructor implied-DO tests

This independent suite records GNU reference outputs and exercises a separately
supplied frozen interpreter. It neither builds an interpreter nor invokes fpm.
No GNU process is an interpreter backend or fallback. Candidate and GNU checks
can run independently; missing candidate evidence is never presented as a pass.

```sh
python3 tests/constructor_implied_do/run_tests.py --self-test
python3 tests/constructor_implied_do/check_generator.py
python3 -m unittest discover -s tests/constructor_implied_do -p test_runner.py
python3 tests/constructor_implied_do/run_tests.py \
  --candidate /absolute/path/to/frozen/fortfront-interpreter \
  --gfortran /absolute/path/to/gfortran \
  --result evidence/combined-results.json
```

`--only REGEX` selects fixtures. `--record-oracles --gfortran PATH` explicitly
records oracle files; this mode forbids a candidate. Ordinary verification never
changes expected outputs. Source fingerprints, expected-output fingerprints,
original-body provenance and comparator self-tests are checked before execution.
The candidate executable SHA-256 is checked before and after the entire suite.
GNU compile commands, statuses, stdout/stderr and execution output are recorded.
Small GNU executables, logs and isolated generator replays are retained under
`evidence/`; they are not required integration files and are not native caches.

## Intended bounded feature

- Untyped numeric, LOGICAL and CHARACTER constructors; existing typed CHARACTER
  constructors. Both `[...]` and `(/.../)` spelling, mixed scalar/array/sibling
  values, multi-item bodies, nesting, and nested constructor expressions.
- Declared scalar INTEGER(4/8) index type/kind. Outer scalar value and definedness
  are unchanged for saved, INTENT(IN) dummy, module, host, active DO and absent
  OPTIONAL outer scalars. A called function sees its own
  normal scope, not a caller's constructor index overlay. The public-IR index does
  not inherit storage attributes. Existing source-level scalar INTEGER
  ALLOCATABLE/POINTER declarations remain unsupported: their four unchanged
  fixtures are subset rejections with GNU compile-only maintenance. Earlier GNU
  executions are retained as independent language-semantics evidence only.
- Forward/reverse/zero-trip loops, zero-trip body non-evaluation, constant-type
  empty results, outer-dependent nested controls, function controls evaluated
  once per loop invocation, and per-iteration scalar/array function results.
- Existing scalar/rank-one leaves only. Rank-two/rank-three leaves, explicit
  index type specifications and nonempty typed numeric constructors are
  deliberate subset rejections, not claimed language-invalid features.
- Boundary fixtures: depth 8/9, body values 64/65, 1,000,000/1,000,001 total
  values and iterations, aggregate nested iteration counts, shared work-budget
  exhaustion, and exactly 16 MiB/16 MiB+1 collected CHARACTER data.
  Large tests retain tiny stdout records, not expanded-array output dumps.
- Invalid same-name array/PARAMETER indices, noninteger indices/controls,
  undeclared indices, own-index value reads in controls, nested index reuse, mixed
  untyped type/kind/length values, malformed controls and constant zero strides.
- Runtime-only checks include dynamic zero strides, undefined bounds/values,
  late bounds errors, checked control
  narrowing, final increment overflow and preservation of undefined outer state.
  Safety negatives preserve an earlier `before` record and may emit nothing
  from a failed statement. CLI evidence does not prove post-error internal state.

## Strict comparison and stage policy

Only success fixtures run under GNU. Every negative is GNU compile-only or a
compile rejection, even if the interpreter is absent or fails. Flags are
`-std=f2018 -pedantic-errors -fcheck=all -O0 -ffree-line-length-none`.
Successful compile, check and run stages require truly empty stderr. Candidate
`--check` stdout must be empty. Candidate exit status is exact: 0 success,
1 compile/subset rejection, 2 checked runtime failure. A missing or timed-out
process is a failure, never a skip.

Formatted and CHARACTER records compare bytes exactly. Numeric list-directed
records permit only horizontal padding and exact Decimal-equivalent D/E
spellings. INTEGER(8) values above 2**53 and neighboring integers must remain
exact. Signed zero, token count, record count, blank records and final newline
are significant. NaN/Infinity (including signed, case-varied payload forms)
never compare equal; real tokens at or above binary64's exact overflow midpoint
are rejected. Tiny Decimal values never silently underflow to zero. Integer
comparison does not go through floating point.

The original `compare_vec_strings` wrapper contains mixed list-directed numeric
and text records. Its `numeric_prefix_exact` comparator permits only leading
padding before a record's integer count. Every byte after that count, every
other CHARACTER record, blank line and newline is exact. The suite does not
claim byte-identical integer field padding. Adversarial tests enforce that
narrow exception and reject changed text spacing or integer precision.

## Exact original source and dependency wrapper

`source/xutilities.f90` is the unchanged original utility input, SHA-256:
`c257f1b2ee4911e979bb38cf6db044d8593c95e76ab1a7e7a7a769a298698883`.
`provenance.json` identifies exact original line ranges and raw body hashes:

- `compare_vec_strings`, lines 675–698, including the original line-686 gate.
- `compare_vec_strings_`, lines 700–721, its direct reverse-comparison dependency.
- `default_character`, lines 3723–3733, the original optional-name dependency.

The complete bodies retain all upstream CRLFs, comments and spaces. Only the
surrounding module, narrowed generic interface and main driver are new. The
wrapper checks duplicates, unequal/equal sets, empty sets on either/both sides,
optional forwarding, absent names and trailing-blank string equality. Original
`default_character` returns LEN(def), so a long optional name is truncated to
one character here; the reference output deliberately preserves that behavior.
The full utility source is only provenance input. This is not a full-library
compilation or correctness claim.

`check_generator.py` regenerates all fixtures/provenance in an isolated retained
tree and proves byte equality and untouched committed inputs. `integration-files.json`
lists the source, scripts, references and concise evidence needed for integration;
local executables and earlier exploratory runs are excluded.

## Additional inquiry and initialization probes

The separate [inquiry followup suite](inquiry-followup/README.md) supplies 22
additional fixtures: 19 valid GNU executions, one GNU-accepted compile-only
scope guard and two GNU compile rejections. They cover PARAMETER/ordinary
initializers, LEN of fixed-length untyped CHARACTER constructors, and nested
constructors inside pending-own-index metadata controls. They are included in
the integration archive, without changing any of the original 95 source files.
Run their separate `inquiry-followup/run_tests.py` in addition to this suite.

## Declaration-boundary correction

The four scalar INTEGER ALLOCATABLE/POINTER fixtures retain identical source
bytes. Their current expectation is compile/subset rejection because the existing
interpreter rejects those declarations before constructor lowering.
`evidence/gnu-verification-before-storage-boundary.json` retains the earlier GNU
execution evidence. `provenance.json` records the distinction transparently.

## GNU-specific evidence and standards

See [SEMANTICS.md](SEMANTICS.md) for primary standards references, the GNU 14.2
constant-folding anomaly and explicit F2018 index-type syntax limitation.

## Observed stage corrections and final evidence

The original95 fixtures remain byte-identical. Two mutable main-program host
association probes are retained as existing-subset rejections; separate module
procedure-host and module-function probes execute and prove the supported
activation isolation. A dynamic TRIM-length untyped constructor rejects during
compilation under the existing fixed-item-length rule. The old million-value
fixture also owns a persistent two-element array and exceeds aggregate storage
on assignment; a separate exact-cap expression-leaf fixture succeeds without
that extra storage. The manifest and generator record these stages, and initial
failure evidence remains retained in the work receipts. No storage or host
association limit was widened to make these tests pass.

Final focused candidate/GNU evidence:99 main cases (53 GNU executions,26
compile-only and20 compile rejections),22 inquiry cases (19 executions,1
compile-only and2 rejections). Native tests separately cover744 source-free
IR/runtime checks,990 producer checks and49 source-adapter checks. Three
complete original utility bodies are preserved. The adapted full utility still
rejects at800:17, external list-directed numeric READ; it does not execute.

Historical evidence/suite-receipt.json records the independent GNU-only preparation stage. The current candidate/native result is evidence/final-receipt.json, results.json and inquiry-followup/verification.json. Earlier receipts are retained rather than rewritten.
