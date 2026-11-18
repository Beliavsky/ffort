# Bounded position edits

Run from the repository root:

```sh
python3 tests/position_formats/test_runner.py
python3 tests/position_formats/check_provenance.py
python3 tests/position_formats/run_tests.py --candidate path/to/fortfront-interpreter --gfortran gfortran
```

The 101 cases use exact byte comparisons: spaces, overwritten characters, record
boundaries and absent final newlines are significant. The suite covers T/TL/TR,
backward overwrite without truncation, gaps that preserve existing text, literal,
PARAMETER and runtime formats, internal files, ordinary and unlimited reversion,
output implied-DO, nested calls, nonadvancing cursor/suffix continuation,
list-directed continuation, format/destination aliasing, resource limits and
atomic failure. Sixteen harness tests include generator/provenance reproduction,
source-located named diagnostics in both phases, crash markers, and separation
of GNU compile-only observations from executions.

Both complete original `demo_cos` and `demo_cosd` programs retain upstream bytes
and run byte-exactly against GNU 14.2. Their source, pinned commit and MIT license
fingerprints are in `upstream.json`. COS uses strict Fortran 2018; COSD uses strict
Fortran 2023, where the degree intrinsic is standardized. There are no helper
substitutions, source reductions or claims of complete M_intrinsics support.

Four cases explicitly do **not** claim GNU agreement. Three forms of
`(a,tr3,tl2,a)` with `A,B` have independently specified `A B` output (plus internal
padding), whereas GNU 14.2 emits `A  B` in advancing/internal output. The
`trailing_backward_nonadvance` case retains the position established by T1 and
therefore produces `a!c`, while GNU 14.2 ignores the trailing tab and emits
`abc !`. The manifest separately pins the candidate expectation and observed
GNU bytes; either changing fails the test. These are not tolerance comparisons.
The same GNU binary was invoked through two aliases, not two compiler versions.

The expectations follow J3/24-007 sections 13.5, 13.8.1 and 12.3.4.4: position
controls update the cursor, preserve previously written text, and a successful
nonadvancing statement leaves that cursor unchanged at completion.
Primary source: https://j3-fortran.org/doc/year/24/24-007.pdf

Some malformed literal formats compile in GNU even with strict flags. They are
marked GNU compile-only successes and never run; candidate rejection remains
required. All failing candidate statements require the named source-located
diagnostic, correct check/run stage and exact prior committed output.
